-- ============================================================
-- Chanda PPC -- v2.7 Addon: Production Log (route-card-free)
--
-- A simple shop-floor entry log, independent of route_cards. Does not
-- touch production_entries (still used by Route Cards / Finished Goods
-- / Dispatch) -- this is an additional, separate table.
--
-- Apply with (PowerShell):
--   Get-Content ppe_schema_addon_v2.7_production_log.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

CREATE TABLE IF NOT EXISTS production_log_entries (
    id                SERIAL PRIMARY KEY,
    line              VARCHAR(30) NOT NULL,        -- 'Tube' | 'Fabrication' | 'Press Shop'
    part_number       VARCHAR(80) NOT NULL,
    entry_date        DATE NOT NULL,
    machine_no        VARCHAR(30),
    operation_name    VARCHAR(100) NOT NULL,
    operator_name     VARCHAR(150),
    start_time        TIME,
    end_time          TIME,
    planned_qty       NUMERIC(12,2),
    produced_qty      NUMERIC(12,2),
    ok_qty            NUMERIC(12,2),
    ng_qty            NUMERIC(12,2),
    rejection_reason  VARCHAR(150),
    entry_by          INTEGER REFERENCES ppe_users(id),
    created_at        TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_production_log_line ON production_log_entries(line);
CREATE INDEX IF NOT EXISTS idx_production_log_date ON production_log_entries(entry_date);
CREATE INDEX IF NOT EXISTS idx_production_log_part ON production_log_entries(part_number);

-- ============================================================
-- END OF ADDON v2.7
-- ============================================================
