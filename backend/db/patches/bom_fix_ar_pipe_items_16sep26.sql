-- ============================================================
-- Chanda PPC -- FIX: AR Pipe items (undo accidental manual edits)
--
-- 1. Item name back to "Tube" (was accidentally changed to "RM: Tube")
-- 2. Spec back to two clean lines: dimensions + Grade
-- 3. "Tube 2" spec back to plain dimensions (accidental "(BOP)" removed)
--
-- Apply with (PowerShell):
--   Get-Content bom_fix_ar_pipe_items_16sep26.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

UPDATE bom_items
SET item_name = 'Tube',
    spec = E'19.05 X 1.4 X 225 MM\nGrade: ERW-3'
WHERE part_number = 'AR Pipe' AND item_name = 'RM: Tube';

-- in case the row was already renamed back to 'Tube' by the time this runs
UPDATE bom_items
SET spec = E'19.05 X 1.4 X 225 MM\nGrade: ERW-3'
WHERE part_number = 'AR Pipe' AND item_name = 'Tube';

UPDATE bom_items
SET spec = '15.88 X 1.5 X 100 MM'
WHERE part_number = 'AR Pipe' AND item_name = 'Tube 2';

-- Verify
SELECT item_name, spec FROM bom_items WHERE part_number = 'AR Pipe' ORDER BY item_seq;

-- ============================================================
-- END
-- ============================================================
