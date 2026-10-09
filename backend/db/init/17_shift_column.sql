-- ============================================================
-- Chanda PPC -- v3.0 Addon: Production Log shift column
--
-- The Handle Bar Report (paper sheet) records Shift A/B per entry;
-- Production Log didn't have this field yet.
--
-- Safe to re-run.
-- Apply with (PowerShell):
--   Get-Content ppe_schema_addon_v3.0_shift.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

ALTER TABLE production_log_entries ADD COLUMN IF NOT EXISTS shift VARCHAR(10);

-- ============================================================
-- END OF ADDON v3.0
-- ============================================================
