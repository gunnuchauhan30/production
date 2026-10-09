-- ============================================================
-- Chanda PPC — Pillion Handle: fix "Sharing" spelling, backfill
-- Power Press machine wherever cycle time is missing (all items)
--
-- Apply with (PowerShell):
--   Get-Content bom_pillion_handle_fixes2.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

UPDATE bom_operations
SET operation_name = 'Shearing'
WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number = 'Pillion Handle')
  AND operation_name = 'Sharing';

UPDATE bom_operations
SET machine_no = 'Power Press'
WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number = 'Pillion Handle')
  AND cycle_time_sec IS NULL;

-- ============================================================
-- END
-- ============================================================
