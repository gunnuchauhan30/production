-- ============================================================
-- Chanda PPC — FIX: J1A Customer Name — 09-Sep-2026
--
-- Requires ppe_schema_addon_v2.6_parts.sql to already be applied
-- (this re-run of it also adds the customer_name column if it's
-- missing from an earlier version of the parts table).
--
-- Apply with (PowerShell), against the already-running database:
--   Get-Content ppe_schema_addon_v2.6_parts.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
--   Get-Content bom_fix_j1a_customer_09sep26.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

INSERT INTO parts (part_number, part_name, customer_name)
VALUES ('J1A', 'Handle Bar', 'UNO MINDA, VARROC')
ON CONFLICT (part_number) DO UPDATE SET
    part_name = EXCLUDED.part_name,
    customer_name = EXCLUDED.customer_name;

-- ============================================================
-- END OF FIX
-- ============================================================
