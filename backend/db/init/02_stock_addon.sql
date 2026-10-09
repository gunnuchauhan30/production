-- ============================================================
-- CHANDA PPE — Schema Addon v2.1: Stock Checking + Shortage Highlight
-- Restores the "Stock Checking" and "Shortage Highlight" steps from the
-- original process flow, but as MANUAL entry (v2.0's zero-touch decision
-- means this is never read from Store's live stock -- a person keeps it
-- updated in PPE, the same way they type in Route Cards).
--
-- Safe to run on top of an already-running chanda_ppe database (does
-- not touch anything from v2.0 -- purely additive, two new tables).
--
-- Apply with:
--   psql -h localhost -U ppe_user -d chanda_ppe -f ppe_schema_addon_v2.1_stock.sql
-- or, if using Docker:
--   docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe < ppe_schema_addon_v2.1_stock.sql
-- ============================================================

-- ------------------------------------------------------------
-- 1. STOCK ITEMS — current on-hand quantity per material, manually kept.
-- current_qty is maintained automatically by a trigger on stock_movements
-- below (never set directly), so it can't drift from the movement log.
-- ------------------------------------------------------------
CREATE TABLE stock_items (
    id              SERIAL PRIMARY KEY,
    material_name   VARCHAR(120) UNIQUE NOT NULL,
    current_qty     NUMERIC(12,2) NOT NULL DEFAULT 0,
    reorder_level   NUMERIC(12,2) NOT NULL DEFAULT 0,
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_stock_items_material ON stock_items(material_name);

-- ------------------------------------------------------------
-- 2. STOCK MOVEMENTS — audit log of every manual stock update.
-- Every receipt or issue is a row here; stock_items.current_qty is
-- derived from this log by a trigger, so there's always a paper trail
-- for "why does this material show 40 units".
-- ------------------------------------------------------------
CREATE TYPE stock_movement_type AS ENUM ('in', 'out');

CREATE TABLE stock_movements (
    id              SERIAL PRIMARY KEY,
    material_name   VARCHAR(120) NOT NULL,
    movement_type   stock_movement_type NOT NULL,
    qty             NUMERIC(12,2) NOT NULL CHECK (qty > 0),
    reason          VARCHAR(150),
    entry_by        INTEGER REFERENCES ppe_users(id),
    entry_date      DATE DEFAULT CURRENT_DATE,
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_stock_movements_material ON stock_movements(material_name);
CREATE INDEX idx_stock_movements_date ON stock_movements(entry_date);

-- Auto-upsert stock_items.current_qty whenever a movement is logged.
CREATE OR REPLACE FUNCTION fn_trg_stock_movement() RETURNS TRIGGER AS $$
DECLARE
    v_delta NUMERIC(12,2) := CASE WHEN NEW.movement_type = 'in' THEN NEW.qty ELSE -NEW.qty END;
BEGIN
    INSERT INTO stock_items (material_name, current_qty)
    VALUES (NEW.material_name, v_delta)
    ON CONFLICT (material_name) DO UPDATE
        SET current_qty = stock_items.current_qty + v_delta,
            updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_stock_movement
    AFTER INSERT ON stock_movements
    FOR EACH ROW EXECUTE FUNCTION fn_trg_stock_movement();

-- ------------------------------------------------------------
-- 3. SHORTAGE VIEW — the "Shortage Highlight" step. Any material below
-- its reorder level shows up here; the Planning page queries this
-- before finalizing a production plan (matches the original flow:
-- Stock Checking -> Shortage Highlight -> Production plan).
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW v_stock_shortage AS
SELECT material_name, current_qty, reorder_level, (reorder_level - current_qty) AS short_by
FROM stock_items
WHERE current_qty < reorder_level;

-- ============================================================
-- END OF ADDON v2.1
-- ============================================================
