-- ============================================================
-- Chanda PPC -- Add "Grade" line below existing spec, batch 1
--
-- Appends a Grade line onto whatever spec text is ALREADY there
-- (does not touch/overwrite the dimensions) -- safe to re-run,
-- won't double-add if a Grade line is already present.
--
-- Apply with (PowerShell):
--   Get-Content bom_add_grades_batch1_16sep26.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

-- BR Pipe : Tube -> Grade: ERW-3
UPDATE bom_items
SET spec = spec || E'\nGrade: ERW-3'
WHERE part_number = 'BR Pipe' AND item_name = 'Tube' AND spec NOT ILIKE '%Grade%';

-- Handle Bar C-350 : Tube -> Grade: ERW-2 MA
UPDATE bom_items
SET spec = spec || E'\nGrade: ERW-2 MA'
WHERE part_number = 'C-350' AND item_name = 'Tube' AND spec NOT ILIKE '%Grade%';

-- D3K : Tube -> Grade: ERW-2 MA
UPDATE bom_items
SET spec = spec || E'\nGrade: ERW-2 MA'
WHERE part_number = 'D3K' AND item_name = 'Tube' AND spec NOT ILIKE '%Grade%';

-- H-100 : Tube -> Grade: ERW-2 MA
UPDATE bom_items
SET spec = spec || E'\nGrade: ERW-2 MA'
WHERE part_number = 'H-100' AND item_name = 'Tube' AND spec NOT ILIKE '%Grade%';

-- Housing Cat items -> Grade: SS409L
-- (matched by item name alone -- these names are unique to Housing Cat)
UPDATE bom_items
SET spec = spec || E'\nGrade: SS409L'
WHERE item_name ILIKE 'Housing Pipe' AND spec NOT ILIKE '%Grade%';

UPDATE bom_items
SET spec = spec || E'\nGrade: SS409L'
WHERE item_name ILIKE 'PERFORATED PIPE' AND spec NOT ILIKE '%Grade%';

UPDATE bom_items
SET spec = spec || E'\nGrade: SS409L'
WHERE item_name ILIKE 'PERFORATED SHEET' AND spec NOT ILIKE '%Grade%';

UPDATE bom_items
SET spec = spec || E'\nGrade: SS409L'
WHERE item_name ILIKE 'Baffle-2' AND spec NOT ILIKE '%Grade%';

UPDATE bom_items
SET spec = spec || E'\nGrade: SS409L'
WHERE item_name ILIKE 'End Plug' AND spec IS NOT NULL AND spec NOT ILIKE '%Grade%';

-- J1-family Tubes -> Grade: ERW-2 MA
UPDATE bom_items
SET spec = spec || E'\nGrade: ERW-2 MA'
WHERE part_number IN ('J1A', 'J1B', 'J1C', 'J1C2', 'J1C5', 'J1C5-2')
  AND item_name = 'Tube'
  AND spec NOT ILIKE '%Grade%';

-- Verify -- every row below should now have a "Grade:" line
SELECT part_number, item_name, spec
FROM bom_items
WHERE (part_number IN ('BR Pipe', 'C-350', 'D3K', 'H-100', 'J1A', 'J1B', 'J1C', 'J1C2', 'J1C5', 'J1C5-2') AND item_name = 'Tube')
   OR item_name IN ('Housing Pipe', 'PERFORATED PIPE', 'PERFORATED SHEET', 'Baffle-2', 'End Plug')
ORDER BY part_number, item_name;

-- ============================================================
-- END
-- ============================================================
