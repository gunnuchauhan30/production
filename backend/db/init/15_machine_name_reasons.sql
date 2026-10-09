-- ============================================================
-- Chanda PPC -- v2.8 Addon: Production Log machine name + extra
-- rejection reasons
--
-- 1. production_log_entries.machine_name  (typed manually on the form)
-- 2. Three new rejection reasons: Power Cut, Machine Breakdown,
--    Material Not Available
--
-- Safe to re-run.
-- Apply with (PowerShell):
--   Get-Content ppe_schema_addon_v2.8_machine_name_reasons.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

ALTER TABLE production_log_entries ADD COLUMN IF NOT EXISTS machine_name VARCHAR(100);

INSERT INTO rejection_reasons (reason, category) VALUES
    ('Power Cut', 'Utility'),
    ('Machine Breakdown', 'Machine'),
    ('Material Not Available', 'Material')
ON CONFLICT (reason) DO NOTHING;

-- Verify
SELECT reason, category FROM rejection_reasons ORDER BY id;

-- ============================================================
-- END OF ADDON v2.8
-- ============================================================
