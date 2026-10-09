-- ============================================================
-- Chanda PPC — Set "Tube 2" (under Pipe AR Pipe) to BOP, no operations
--
-- Apply with (PowerShell):
--   Get-Content bom_tube2_to_bop.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

DELETE FROM bom_operations
WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number = 'AR Pipe' AND item_name = 'Tube 2');

UPDATE bom_items SET spec = 'BOP'
WHERE part_number = 'AR Pipe' AND item_name = 'Tube 2';

-- ============================================================
-- END
-- ============================================================
