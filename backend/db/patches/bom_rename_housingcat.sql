-- ============================================================
-- Chanda PPC — Rename "Housing Housing Cat" -> "Housing Cat Assembly"
-- Done as insert-new / repoint-children / delete-old, so it's safe
-- whether or not a foreign key exists between bom_items.part_number
-- and parts.part_number.
--
-- Apply with (PowerShell):
--   Get-Content bom_rename_housingcat.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

BEGIN;

INSERT INTO parts (part_number, part_name, customer_name)
SELECT 'Housing Cat Assembly', '', customer_name FROM parts WHERE part_number = 'Housing Cat';

UPDATE bom_items SET part_number = 'Housing Cat Assembly' WHERE part_number = 'Housing Cat';

DELETE FROM parts WHERE part_number = 'Housing Cat';

COMMIT;

-- ============================================================
-- END
-- ============================================================
