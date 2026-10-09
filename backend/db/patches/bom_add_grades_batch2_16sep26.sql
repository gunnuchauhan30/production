-- ============================================================
-- Chanda PPC -- Add "Grade" line below existing spec, batch 2
--
-- Same safe append approach as batch 1: only adds a Grade line if
-- one isn't already there, doesn't touch the dimensions. Item name
-- matched case-insensitively (J1A's Tube is now named "TUBE").
--
-- Apply with (PowerShell):
--   Get-Content bom_add_grades_batch2_16sep26.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

UPDATE bom_items
SET spec = spec || E'\nGrade: ERW-2 MA'
WHERE part_number = 'J1A' AND item_name ILIKE 'Tube' AND spec NOT ILIKE '%Grade%';

UPDATE bom_items
SET spec = spec || E'\nGrade: ERW-2 MA'
WHERE part_number = 'J1D1' AND item_name ILIKE 'Tube' AND spec NOT ILIKE '%Grade%';

UPDATE bom_items
SET spec = spec || E'\nGrade: ERW-2 MA'
WHERE part_number = 'K0-2' AND item_name ILIKE 'Tube' AND spec NOT ILIKE '%Grade%';

UPDATE bom_items
SET spec = spec || E'\nGrade: ERW-1'
WHERE part_number = 'N-40' AND item_name ILIKE 'Tube' AND spec NOT ILIKE '%Grade%';

UPDATE bom_items
SET spec = spec || E'\nGrade: ERW-1'
WHERE part_number = 'U-143' AND item_name ILIKE 'Tube' AND spec NOT ILIKE '%Grade%';

UPDATE bom_items
SET spec = spec || E'\nGrade: ERW-1'
WHERE part_number = 'U-349C' AND item_name ILIKE 'Tube' AND spec NOT ILIKE '%Grade%';

UPDATE bom_items
SET spec = spec || E'\nGrade: ERW-2 MA'
WHERE part_number = 'U4D' AND item_name ILIKE 'Tube' AND spec NOT ILIKE '%Grade%';

UPDATE bom_items
SET spec = spec || E'\nGrade: ERW-2 MA'
WHERE part_number = 'V1F' AND item_name ILIKE 'Tube' AND spec NOT ILIKE '%Grade%';

-- Verify -- every row below should now show a "Grade:" line
SELECT part_number, item_name, spec
FROM bom_items
WHERE part_number IN ('J1A', 'J1D1', 'K0-2', 'N-40', 'U-143', 'U-349C', 'U4D', 'V1F')
  AND item_name ILIKE 'Tube'
ORDER BY part_number;

-- ============================================================
-- END
-- ============================================================
