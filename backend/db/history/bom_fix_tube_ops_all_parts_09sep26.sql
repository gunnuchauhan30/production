-- ============================================================
-- Chanda PPC -- FIX: Tube operations for all Handle Bar parts
-- Parts: J1A, J1B, J1C, J1C2, J1C5, J1C5-1, J1C5-2, J1D1, V1F
--
-- Full corrected 12-step Tube operation list, applied to the
-- 'Tube' BOM item of every listed part (replaces whatever
-- operations it currently has, so it's safe to re-run).
--
-- Apply with (PowerShell):
--   Get-Content bom_fix_tube_ops_all_parts_09sep26.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

DELETE FROM bom_operations
WHERE bom_item_id IN (
    SELECT id FROM bom_items WHERE item_name = 'Tube' AND part_number IN ('J1A', 'J1B', 'J1C', 'J1C2', 'J1C5', 'J1C5-1', 'J1C5-2', 'J1D1', 'V1F')
);

-- ---------- J1A : Tube ----------
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Stamping', 10, NULL),
    (2, 'Knurling', 16, NULL),
    (3, 'Bending', 25, NULL),
    (4, 'Bush Drill - 105MM', 16, NULL),
    (5, 'Drilling LHS', 16, NULL),
    (6, 'Drilling RHS', 16, NULL),
    (7, 'Burr Remove', 16, NULL),
    (8, 'Center Marking', 18, NULL),
    (9, 'RHS Side Marking', 18, NULL),
    (10, 'LHS Side Marking', 18, NULL),
    (11, 'Bush Drill', 21, NULL),
    (12, 'Reamer', 38, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'J1A' AND b.item_name = 'Tube';

-- ---------- J1B : Tube ----------
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Stamping', 10, NULL),
    (2, 'Knurling', 16, NULL),
    (3, 'Bending', 25, NULL),
    (4, 'Bush Drill - 105MM', 16, NULL),
    (5, 'Drilling LHS', 16, NULL),
    (6, 'Drilling RHS', 16, NULL),
    (7, 'Burr Remove', 16, NULL),
    (8, 'Center Marking', 18, NULL),
    (9, 'RHS Side Marking', 18, NULL),
    (10, 'LHS Side Marking', 18, NULL),
    (11, 'Bush Drill', 21, NULL),
    (12, 'Reamer', 38, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'J1B' AND b.item_name = 'Tube';

-- ---------- J1C : Tube ----------
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Stamping', 10, NULL),
    (2, 'Knurling', 16, NULL),
    (3, 'Bending', 25, NULL),
    (4, 'Bush Drill - 105MM', 16, NULL),
    (5, 'Drilling LHS', 16, NULL),
    (6, 'Drilling RHS', 16, NULL),
    (7, 'Burr Remove', 16, NULL),
    (8, 'Center Marking', 18, NULL),
    (9, 'RHS Side Marking', 18, NULL),
    (10, 'LHS Side Marking', 18, NULL),
    (11, 'Bush Drill', 21, NULL),
    (12, 'Reamer', 38, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'J1C' AND b.item_name = 'Tube';

-- ---------- J1C2 : Tube ----------
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Stamping', 10, NULL),
    (2, 'Knurling', 16, NULL),
    (3, 'Bending', 25, NULL),
    (4, 'Bush Drill - 105MM', 16, NULL),
    (5, 'Drilling LHS', 16, NULL),
    (6, 'Drilling RHS', 16, NULL),
    (7, 'Burr Remove', 16, NULL),
    (8, 'Center Marking', 18, NULL),
    (9, 'RHS Side Marking', 18, NULL),
    (10, 'LHS Side Marking', 18, NULL),
    (11, 'Bush Drill', 21, NULL),
    (12, 'Reamer', 38, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'J1C2' AND b.item_name = 'Tube';

-- ---------- J1C5 : Tube ----------
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Stamping', 10, NULL),
    (2, 'Knurling', 16, NULL),
    (3, 'Bending', 25, NULL),
    (4, 'Bush Drill - 105MM', 16, NULL),
    (5, 'Drilling LHS', 16, NULL),
    (6, 'Drilling RHS', 16, NULL),
    (7, 'Burr Remove', 16, NULL),
    (8, 'Center Marking', 18, NULL),
    (9, 'RHS Side Marking', 18, NULL),
    (10, 'LHS Side Marking', 18, NULL),
    (11, 'Bush Drill', 21, NULL),
    (12, 'Reamer', 38, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'J1C5' AND b.item_name = 'Tube';

-- ---------- J1C5-1 : Tube ----------
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Stamping', 10, NULL),
    (2, 'Knurling', 16, NULL),
    (3, 'Bending', 25, NULL),
    (4, 'Bush Drill - 105MM', 16, NULL),
    (5, 'Drilling LHS', 16, NULL),
    (6, 'Drilling RHS', 16, NULL),
    (7, 'Burr Remove', 16, NULL),
    (8, 'Center Marking', 18, NULL),
    (9, 'RHS Side Marking', 18, NULL),
    (10, 'LHS Side Marking', 18, NULL),
    (11, 'Bush Drill', 21, NULL),
    (12, 'Reamer', 38, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'J1C5-1' AND b.item_name = 'Tube';

-- ---------- J1C5-2 : Tube ----------
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Stamping', 10, NULL),
    (2, 'Knurling', 16, NULL),
    (3, 'Bending', 25, NULL),
    (4, 'Bush Drill - 105MM', 16, NULL),
    (5, 'Drilling LHS', 16, NULL),
    (6, 'Drilling RHS', 16, NULL),
    (7, 'Burr Remove', 16, NULL),
    (8, 'Center Marking', 18, NULL),
    (9, 'RHS Side Marking', 18, NULL),
    (10, 'LHS Side Marking', 18, NULL),
    (11, 'Bush Drill', 21, NULL),
    (12, 'Reamer', 38, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'J1C5-2' AND b.item_name = 'Tube';

-- ---------- J1D1 : Tube ----------
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Stamping', 10, NULL),
    (2, 'Knurling', 16, NULL),
    (3, 'Bending', 25, NULL),
    (4, 'Bush Drill - 105MM', 16, NULL),
    (5, 'Drilling LHS', 16, NULL),
    (6, 'Drilling RHS', 16, NULL),
    (7, 'Burr Remove', 16, NULL),
    (8, 'Center Marking', 18, NULL),
    (9, 'RHS Side Marking', 18, NULL),
    (10, 'LHS Side Marking', 18, NULL),
    (11, 'Bush Drill', 21, NULL),
    (12, 'Reamer', 38, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'J1D1' AND b.item_name = 'Tube';

-- ---------- V1F : Tube ----------
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Stamping', 10, NULL),
    (2, 'Knurling', 16, NULL),
    (3, 'Bending', 25, NULL),
    (4, 'Bush Drill - 105MM', 16, NULL),
    (5, 'Drilling LHS', 16, NULL),
    (6, 'Drilling RHS', 16, NULL),
    (7, 'Burr Remove', 16, NULL),
    (8, 'Center Marking', 18, NULL),
    (9, 'RHS Side Marking', 18, NULL),
    (10, 'LHS Side Marking', 18, NULL),
    (11, 'Bush Drill', 21, NULL),
    (12, 'Reamer', 38, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'V1F' AND b.item_name = 'Tube';

-- ============================================================
-- END
-- ============================================================
