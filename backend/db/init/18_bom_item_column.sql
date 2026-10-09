-- ============================================================
-- Chanda PPC -- v3.1 Addon: Production Log -- BOM Item column
--
-- Lets a Production Log entry record WHICH BOM item (Tube, Housing Pipe,
-- Assembly, etc.) an operation belongs to, not just the part -- needed
-- because operation names like "Flaring" or "Punching" can repeat across
-- a part's different items with different cycle times each.
--
-- Safe to re-run.
-- Apply with (PowerShell):
--   Get-Content ppe_schema_addon_v3.1_bom_item.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

ALTER TABLE production_log_entries ADD COLUMN IF NOT EXISTS bom_item_name VARCHAR(100);

-- ============================================================
-- END OF ADDON v3.1
-- ============================================================
