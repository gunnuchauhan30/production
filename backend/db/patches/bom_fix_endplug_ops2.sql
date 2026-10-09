-- ============================================================
-- Chanda PPC — FIX 2: End Plug operations (part was renamed to
-- "Housing Cat Assembly" after the previous fix file was written)
--
-- Apply with (PowerShell):
--   Get-Content bom_fix_endplug_ops2.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

DELETE FROM bom_operations WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number = 'Housing Cat Assembly' AND item_name = 'End Plug');

INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec::numeric, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Shearing', NULL, 'Power Press'),
    (2, 'Blank',    NULL, 'Power Press'),
    (3, 'Draw',     NULL, 'Power Press')
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'Housing Cat Assembly' AND b.item_name = 'End Plug';

-- ============================================================
-- END
-- ============================================================
