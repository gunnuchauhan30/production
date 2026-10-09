-- ============================================================
-- Chanda PPC — Remove "Long Bush" BOM item from H-100, N-40, U-143, U-349C
-- (ON DELETE CASCADE on bom_operations means any ops under it go too,
-- but these were BOP/empty anyway.)
--
-- Apply with (PowerShell):
--   Get-Content bom_remove_longbush_4parts.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

DELETE FROM bom_items
WHERE part_number IN ('H-100', 'N-40', 'U-143', 'U-349C')
  AND item_name ILIKE 'Long Bush%';

-- ============================================================
-- END
-- ============================================================
