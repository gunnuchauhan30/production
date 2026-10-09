-- ============================================================
-- Chanda PPC -- v2.9 Addon: Production Log -> automatic OEE
--
-- Adds the OEE input/output columns to production_log_entries and
-- seeds the down_time_reasons master list (separate from rejection
-- reasons, which are for quality/NG, not downtime).
--
-- Safe to re-run.
-- Apply with (PowerShell):
--   Get-Content ppe_schema_addon_v2.9_production_log_oee.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

ALTER TABLE production_log_entries ADD COLUMN IF NOT EXISTS standard_cycle_time_sec NUMERIC(10,2);
ALTER TABLE production_log_entries ADD COLUMN IF NOT EXISTS extra_down_time_min     NUMERIC(10,2);
ALTER TABLE production_log_entries ADD COLUMN IF NOT EXISTS down_time_reason        VARCHAR(150);
ALTER TABLE production_log_entries ADD COLUMN IF NOT EXISTS total_time_min          NUMERIC(10,2);
ALTER TABLE production_log_entries ADD COLUMN IF NOT EXISTS planned_down_time_min   NUMERIC(10,2);
ALTER TABLE production_log_entries ADD COLUMN IF NOT EXISTS down_time_min           NUMERIC(10,2);
ALTER TABLE production_log_entries ADD COLUMN IF NOT EXISTS run_time_min            NUMERIC(10,2);
ALTER TABLE production_log_entries ADD COLUMN IF NOT EXISTS availability            NUMERIC(6,5);
ALTER TABLE production_log_entries ADD COLUMN IF NOT EXISTS performance             NUMERIC(6,5);
ALTER TABLE production_log_entries ADD COLUMN IF NOT EXISTS quality                 NUMERIC(6,5);
ALTER TABLE production_log_entries ADD COLUMN IF NOT EXISTS oee                     NUMERIC(6,5);

INSERT INTO down_time_reasons (reason) VALUES
    ('Power Cut'),
    ('Machine Breakdown'),
    ('Material Not Available')
ON CONFLICT (reason) DO NOTHING;

-- Verify
SELECT reason FROM down_time_reasons ORDER BY id;

-- ============================================================
-- END OF ADDON v2.9
-- ============================================================
