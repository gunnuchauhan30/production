-- ============================================================
-- Chanda PPC — FIX 2: J1A BOM Operations (final corrected list)
-- Replaces the previous (wrong) 14-op list with the user-corrected one.
-- Applies identically to both RM and Long Bush under J1A.
--
-- Apply with (PowerShell):
--   Get-Content bom_fix_j1a_final.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

DELETE FROM bom_operations
WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number = 'J1A');

INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1,  'Stamping',             10, NULL),
    (2,  'Knurling',             16, NULL),
    (3,  'Bending',              25, NULL),
    (4,  'Bush Drill - 105MM',   16, NULL),
    (5,  'Drilling LHS',         16, NULL),
    (6,  'Drilling RHS',         16, NULL),
    (7,  'Burr Remove',          16, NULL),
    (8,  'Center Marking',       18, NULL),
    (9,  'RHS Side Marking',     18, NULL),
    (10, 'Bush Drill',           21, NULL),
    (11, 'Reamer',               38, NULL),
    (12, 'Welding',              70, NULL),
    (13, 'Grinding',             32, NULL),
    (14, 'Gauging',              20, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'J1A';

-- ============================================================
-- END OF FIX
-- ============================================================
