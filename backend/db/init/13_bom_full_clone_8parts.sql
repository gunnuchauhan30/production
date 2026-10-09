-- ============================================================
-- Chanda PPC -- FULL CLONE of 'Handle Bar J1A' onto 8 more parts
-- Parts: J1B, J1C, J1C2, J1C5, J1C5-1, J1C5-2, J1D1, V1F
--
-- This makes EVERY one of these parts an exact copy of J1A:
--   Part name : Handle Bar   |   Customer: UNO MINDA, VARROC
--   Tube      : spec '22.2 X 2 X 841 MM', 12 operations (Stamping...Reamer)
--   Long Bush {PART} : BOP, no operations
--   Assembly  : Welding 70s, Grinding 32s, Gauging 20s
--
-- 100% safe to run more than once (updates/replaces, no duplicates).
--
-- Apply with (PowerShell):
--   Get-Content bom_full_clone_j1a_to_8parts_10sep26.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

-- ================= J1B =================
INSERT INTO parts (part_number, part_name, customer_name) VALUES ('J1B', 'Handle Bar', 'UNO MINDA, VARROC')
ON CONFLICT (part_number) DO UPDATE SET part_name = EXCLUDED.part_name, customer_name = EXCLUDED.customer_name;

INSERT INTO bom_items (part_number, item_name, spec, item_seq) VALUES
    ('J1B', 'Tube', '22.2 X 2 X 841 MM', 1),
    ('J1B', 'Long Bush J1B', 'BOP', 2),
    ('J1B', 'Assembly', NULL, 3)
ON CONFLICT (part_number, item_name) DO UPDATE SET spec = EXCLUDED.spec, item_seq = EXCLUDED.item_seq;

DELETE FROM bom_operations WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number = 'J1B');

-- J1B : Tube operations
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

-- J1B : Assembly operations
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Welding', 70, NULL),
    (2, 'Grinding', 32, NULL),
    (3, 'Gauging', 20, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'J1B' AND b.item_name = 'Assembly';

-- Long Bush J1B intentionally gets NO operations (BOP)

-- ================= J1C =================
INSERT INTO parts (part_number, part_name, customer_name) VALUES ('J1C', 'Handle Bar', 'UNO MINDA, VARROC')
ON CONFLICT (part_number) DO UPDATE SET part_name = EXCLUDED.part_name, customer_name = EXCLUDED.customer_name;

INSERT INTO bom_items (part_number, item_name, spec, item_seq) VALUES
    ('J1C', 'Tube', '22.2 X 2 X 841 MM', 1),
    ('J1C', 'Long Bush J1C', 'BOP', 2),
    ('J1C', 'Assembly', NULL, 3)
ON CONFLICT (part_number, item_name) DO UPDATE SET spec = EXCLUDED.spec, item_seq = EXCLUDED.item_seq;

DELETE FROM bom_operations WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number = 'J1C');

-- J1C : Tube operations
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

-- J1C : Assembly operations
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Welding', 70, NULL),
    (2, 'Grinding', 32, NULL),
    (3, 'Gauging', 20, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'J1C' AND b.item_name = 'Assembly';

-- Long Bush J1C intentionally gets NO operations (BOP)

-- ================= J1C2 =================
INSERT INTO parts (part_number, part_name, customer_name) VALUES ('J1C2', 'Handle Bar', 'UNO MINDA, VARROC')
ON CONFLICT (part_number) DO UPDATE SET part_name = EXCLUDED.part_name, customer_name = EXCLUDED.customer_name;

INSERT INTO bom_items (part_number, item_name, spec, item_seq) VALUES
    ('J1C2', 'Tube', '22.2 X 2 X 841 MM', 1),
    ('J1C2', 'Long Bush J1C2', 'BOP', 2),
    ('J1C2', 'Assembly', NULL, 3)
ON CONFLICT (part_number, item_name) DO UPDATE SET spec = EXCLUDED.spec, item_seq = EXCLUDED.item_seq;

DELETE FROM bom_operations WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number = 'J1C2');

-- J1C2 : Tube operations
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

-- J1C2 : Assembly operations
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Welding', 70, NULL),
    (2, 'Grinding', 32, NULL),
    (3, 'Gauging', 20, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'J1C2' AND b.item_name = 'Assembly';

-- Long Bush J1C2 intentionally gets NO operations (BOP)

-- ================= J1C5 =================
INSERT INTO parts (part_number, part_name, customer_name) VALUES ('J1C5', 'Handle Bar', 'UNO MINDA, VARROC')
ON CONFLICT (part_number) DO UPDATE SET part_name = EXCLUDED.part_name, customer_name = EXCLUDED.customer_name;

INSERT INTO bom_items (part_number, item_name, spec, item_seq) VALUES
    ('J1C5', 'Tube', '22.2 X 2 X 841 MM', 1),
    ('J1C5', 'Long Bush J1C5', 'BOP', 2),
    ('J1C5', 'Assembly', NULL, 3)
ON CONFLICT (part_number, item_name) DO UPDATE SET spec = EXCLUDED.spec, item_seq = EXCLUDED.item_seq;

DELETE FROM bom_operations WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number = 'J1C5');

-- J1C5 : Tube operations
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

-- J1C5 : Assembly operations
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Welding', 70, NULL),
    (2, 'Grinding', 32, NULL),
    (3, 'Gauging', 20, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'J1C5' AND b.item_name = 'Assembly';

-- Long Bush J1C5 intentionally gets NO operations (BOP)

-- ================= J1C5-1 =================
INSERT INTO parts (part_number, part_name, customer_name) VALUES ('J1C5-1', 'Handle Bar', 'UNO MINDA, VARROC')
ON CONFLICT (part_number) DO UPDATE SET part_name = EXCLUDED.part_name, customer_name = EXCLUDED.customer_name;

INSERT INTO bom_items (part_number, item_name, spec, item_seq) VALUES
    ('J1C5-1', 'Tube', '22.2 X 2 X 841 MM', 1),
    ('J1C5-1', 'Long Bush J1C5-1', 'BOP', 2),
    ('J1C5-1', 'Assembly', NULL, 3)
ON CONFLICT (part_number, item_name) DO UPDATE SET spec = EXCLUDED.spec, item_seq = EXCLUDED.item_seq;

DELETE FROM bom_operations WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number = 'J1C5-1');

-- J1C5-1 : Tube operations
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

-- J1C5-1 : Assembly operations
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Welding', 70, NULL),
    (2, 'Grinding', 32, NULL),
    (3, 'Gauging', 20, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'J1C5-1' AND b.item_name = 'Assembly';

-- Long Bush J1C5-1 intentionally gets NO operations (BOP)

-- ================= J1C5-2 =================
INSERT INTO parts (part_number, part_name, customer_name) VALUES ('J1C5-2', 'Handle Bar', 'UNO MINDA, VARROC')
ON CONFLICT (part_number) DO UPDATE SET part_name = EXCLUDED.part_name, customer_name = EXCLUDED.customer_name;

INSERT INTO bom_items (part_number, item_name, spec, item_seq) VALUES
    ('J1C5-2', 'Tube', '22.2 X 2 X 841 MM', 1),
    ('J1C5-2', 'Long Bush J1C5-2', 'BOP', 2),
    ('J1C5-2', 'Assembly', NULL, 3)
ON CONFLICT (part_number, item_name) DO UPDATE SET spec = EXCLUDED.spec, item_seq = EXCLUDED.item_seq;

DELETE FROM bom_operations WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number = 'J1C5-2');

-- J1C5-2 : Tube operations
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

-- J1C5-2 : Assembly operations
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Welding', 70, NULL),
    (2, 'Grinding', 32, NULL),
    (3, 'Gauging', 20, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'J1C5-2' AND b.item_name = 'Assembly';

-- Long Bush J1C5-2 intentionally gets NO operations (BOP)

-- ================= J1D1 =================
INSERT INTO parts (part_number, part_name, customer_name) VALUES ('J1D1', 'Handle Bar', 'UNO MINDA, VARROC')
ON CONFLICT (part_number) DO UPDATE SET part_name = EXCLUDED.part_name, customer_name = EXCLUDED.customer_name;

INSERT INTO bom_items (part_number, item_name, spec, item_seq) VALUES
    ('J1D1', 'Tube', '22.2 X 2 X 841 MM', 1),
    ('J1D1', 'Long Bush J1D1', 'BOP', 2),
    ('J1D1', 'Assembly', NULL, 3)
ON CONFLICT (part_number, item_name) DO UPDATE SET spec = EXCLUDED.spec, item_seq = EXCLUDED.item_seq;

DELETE FROM bom_operations WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number = 'J1D1');

-- J1D1 : Tube operations
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

-- J1D1 : Assembly operations
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Welding', 70, NULL),
    (2, 'Grinding', 32, NULL),
    (3, 'Gauging', 20, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'J1D1' AND b.item_name = 'Assembly';

-- Long Bush J1D1 intentionally gets NO operations (BOP)

-- ================= V1F =================
INSERT INTO parts (part_number, part_name, customer_name) VALUES ('V1F', 'Handle Bar', 'UNO MINDA, VARROC')
ON CONFLICT (part_number) DO UPDATE SET part_name = EXCLUDED.part_name, customer_name = EXCLUDED.customer_name;

INSERT INTO bom_items (part_number, item_name, spec, item_seq) VALUES
    ('V1F', 'Tube', '22.2 X 2 X 841 MM', 1),
    ('V1F', 'Long Bush V1F', 'BOP', 2),
    ('V1F', 'Assembly', NULL, 3)
ON CONFLICT (part_number, item_name) DO UPDATE SET spec = EXCLUDED.spec, item_seq = EXCLUDED.item_seq;

DELETE FROM bom_operations WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number = 'V1F');

-- V1F : Tube operations
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

-- V1F : Assembly operations
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Welding', 70, NULL),
    (2, 'Grinding', 32, NULL),
    (3, 'Gauging', 20, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'V1F' AND b.item_name = 'Assembly';

-- Long Bush V1F intentionally gets NO operations (BOP)

-- ============================================================
-- END
-- ============================================================
