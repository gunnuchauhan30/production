-- ============================================================
-- Chanda PPC -- J1A : Tube -> add Grade: ERW-2 MA
-- (earlier attempts missed this because the item was briefly
-- renamed to "Tubecota"; it's back to "Tube" now)
--
-- Apply with (PowerShell):
--   Get-Content bom_j1a_tube_grade_16sep26.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

UPDATE bom_items
SET spec = spec || E'\nGrade: ERW-2 MA'
WHERE part_number = 'J1A' AND item_name ILIKE 'Tube' AND spec NOT ILIKE '%Grade%';

-- Verify
SELECT item_name, spec FROM bom_items WHERE part_number = 'J1A' ORDER BY item_seq;

-- ============================================================
-- END
-- ============================================================
