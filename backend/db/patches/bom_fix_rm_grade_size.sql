-- ============================================================
-- Chanda PPC — Fix RM/Grade/Size mapping for AR Pipe & BR Pipe Tube
-- Correct mapping: RM = Tube, Grade = ERW-3, Size = dimension
--
-- Apply with (PowerShell):
--   Get-Content bom_fix_rm_grade_size.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

UPDATE bom_items
SET spec = 'RM: Tube, Grade: ERW-3, Size: 19.05 X 1.4 X 225 MM'
WHERE part_number = 'AR Pipe' AND item_name = 'Tube';

UPDATE bom_items
SET spec = 'RM: Tube, Grade: ERW-3, Size: 13.05 X 1.4 X 315 MM'
WHERE part_number = 'BR Pipe' AND item_name = 'Tube';

-- ============================================================
-- END
-- ============================================================
