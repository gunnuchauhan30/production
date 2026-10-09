-- ============================================================
-- Chanda PPC — FIX: J1A BOM Operations
--
-- Previous seed wrongly split the 14 operations between RM (3 ops)
-- and Long Bush (11 ops). Correct behaviour: BOTH BOM items show the
-- SAME full 14-operation list, numbered 1-14 exactly as on the sheet.
--
-- This wipes and re-inserts bom_operations for J1A's RM and Long Bush
-- only -- nothing else is touched.
--
-- Apply with (PowerShell):
--   Get-Content bom_fix_j1a_full_ops.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

DELETE FROM bom_operations
WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number = 'J1A');

INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1,  'Slitting',           10, NULL),
    (2,  'Bending',            15, NULL),
    (3,  'Bending',            35, NULL),
    (4,  'Bush Drill - 105MM', 15, NULL),
    (5,  'Knurling',           15, NULL),
    (6,  'Drilling',           16, NULL),
    (7,  'Button Remove',      16, NULL),
    (8,  'Center Marking',     18, NULL),
    (9,  'Bush Side Marking',  18, NULL),
    (10, 'Bush Drill',         21, NULL),
    (11, 'Reamer',             38, NULL),
    (12, 'Welding',            70, NULL),
    (13, 'Grinding',           32, NULL),
    (14, 'Gauging',            20, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'J1A';

-- ============================================================
-- END OF FIX
-- ============================================================
