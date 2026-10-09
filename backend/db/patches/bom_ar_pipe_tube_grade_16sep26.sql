-- ============================================================
-- Chanda PPC -- Add Grade to AR Pipe's Tube (19.05 X 1.4 X 225 MM)
--
-- Adds a second line under the dimensions showing "Grade: ERW-3".
-- (Only touches the first Tube -- not "Tube 2".)
--
-- Apply with (PowerShell):
--   Get-Content bom_ar_pipe_tube_grade_16sep26.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

UPDATE bom_items
SET spec = E'19.05 X 1.4 X 225 MM\nGrade: ERW-3'
WHERE part_number = 'AR Pipe' AND item_name = 'Tube';

-- ============================================================
-- END
-- ============================================================
