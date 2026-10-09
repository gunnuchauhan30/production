-- ============================================================
-- Chanda PPC — Pillion Handle: backfill machine = Power Press
-- wherever cycle time is missing (Tube, Patti, UBKT operations)
--
-- Apply with (PowerShell):
--   Get-Content bom_pillion_handle_powerpress.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

UPDATE bom_operations
SET machine_no = 'Power Press'
WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number = 'Pillion Handle')
  AND cycle_time_sec IS NULL;

-- ============================================================
-- END
-- ============================================================
