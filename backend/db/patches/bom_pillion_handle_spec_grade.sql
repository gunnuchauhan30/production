-- ============================================================
-- Chanda PPC — Pillion Handle: put Grade into spec (2nd line),
-- since that's what the frontend actually displays.
--
-- Apply with (PowerShell):
--   Get-Content bom_pillion_handle_spec_grade.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

UPDATE bom_items SET spec = E'271 X 1250 X 2.0 MM\nGrade: HROP'
WHERE part_number = 'Pillion Handle' AND item_name = 'Sheet';

UPDATE bom_items SET spec = E'43 X 1250 X 2.0 MM\nGrade: HROP'
WHERE part_number = 'Pillion Handle' AND item_name = 'Patti';

UPDATE bom_items SET spec = E'32 X 1.5 MM\nGrade: HROP'
WHERE part_number = 'Pillion Handle' AND item_name = 'UBKT';

-- ============================================================
-- END
-- ============================================================
