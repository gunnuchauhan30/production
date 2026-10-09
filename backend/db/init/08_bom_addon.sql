-- ============================================================
-- Chanda PPC — v2.5 Addon: BOM Items + Per-Item Operations
--
-- New hierarchy for master data browsing: Part -> BOM Item -> Operations.
-- This is ADDITIVE and does not touch part_routing (which production
-- entries still validate against) -- it's a separate, cleaner
-- reference structure for the Master Data screen.
--
-- Apply with (PowerShell):
--   Get-Content ppe_schema_addon_v2.5_bom.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

CREATE TABLE IF NOT EXISTS bom_items (
    id            SERIAL PRIMARY KEY,
    part_number   VARCHAR(80) NOT NULL,
    item_name     VARCHAR(100) NOT NULL,      -- e.g. "RM", "Long Bush"
    spec          VARCHAR(150),                -- e.g. "22.2 X 2.0 X 891 MM"
    item_seq      INT NOT NULL DEFAULT 1,
    CONSTRAINT uq_bom_part_item UNIQUE (part_number, item_name)
);
CREATE INDEX IF NOT EXISTS idx_bom_items_part ON bom_items(part_number);

CREATE TABLE IF NOT EXISTS bom_operations (
    id              SERIAL PRIMARY KEY,
    bom_item_id     INT NOT NULL REFERENCES bom_items(id) ON DELETE CASCADE,
    operation_seq   INT NOT NULL,
    operation_name  VARCHAR(100) NOT NULL,
    cycle_time_sec  NUMERIC(10,2),
    machine_no      VARCHAR(80),
    CONSTRAINT uq_bomop_item_seq UNIQUE (bom_item_id, operation_seq)
);

-- ============================================================
-- END OF ADDON v2.5
-- ============================================================
