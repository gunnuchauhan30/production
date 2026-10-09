-- ============================================================
-- Chanda PPC — Add RM/Grade/RM Size details to Tube spec
-- for AR Pipe and BR Pipe (appended to existing spec text)
--
-- Apply with (PowerShell):
--   Get-Content bom_add_rm_details_pipes.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

UPDATE bom_items
SET spec = '19.05 X 1.4 X 225 MM | RM: Tube, Grade: Tube, RM Size: ERW-3'
WHERE part_number = 'AR Pipe' AND item_name = 'Tube';

UPDATE bom_items
SET spec = '13.05 X 1.4 X 315 MM | RM: Tube, Grade: Tube, RM Size: ERW-3'
WHERE part_number = 'BR Pipe' AND item_name = 'Tube';

-- ============================================================
-- END
-- ============================================================
