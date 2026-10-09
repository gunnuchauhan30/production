-- ============================================================
-- Chanda PPC — New Parts (Customer: MINDA): H-100, N-40, U-349C, U-143
-- Structure: Tube / Long Bush {PART} (BOP, no ops) -- NO Assembly item,
-- since none of these have Welding/Grinding steps.
--
-- Apply with (PowerShell):
--   Get-Content bom_new_parts_minda_4parts.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

INSERT INTO parts (part_number, part_name, customer_name) VALUES
    ('H-100',  'Handle Bar', 'MINDA'),
    ('N-40',   'Handle Bar', 'MINDA'),
    ('U-349C', 'Handle Bar', 'MINDA'),
    ('U-143',  'Handle Bar', 'MINDA')
ON CONFLICT (part_number) DO UPDATE SET part_name = EXCLUDED.part_name, customer_name = EXCLUDED.customer_name;

INSERT INTO bom_items (part_number, item_name, spec, item_seq) VALUES
    ('H-100',  'Tube',              '22.20 X 2.0 X 816 MM', 1),
    ('H-100',  'Long Bush H-100',   'BOP',                   2),
    ('N-40',   'Tube',              '22.2 X 2 X 907 MM',    1),
    ('N-40',   'Long Bush N-40',    'BOP',                   2),
    ('U-349C', 'Tube',              '22.2 X 2 X 807 MM',    1),
    ('U-349C', 'Long Bush U-349C',  'BOP',                   2),
    ('U-143',  'Tube',              '22.2 X 2 X 807 MM',    1),
    ('U-143',  'Long Bush U-143',   'BOP',                   2)
ON CONFLICT (part_number, item_name) DO UPDATE SET spec = EXCLUDED.spec, item_seq = EXCLUDED.item_seq;

DELETE FROM bom_operations
WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number IN ('H-100', 'N-40', 'U-349C', 'U-143'));

-- ===== H-100 : Tube (17 ops) =====
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1,  'Stamping',              10, NULL),
    (2,  'Knurling',              16, NULL),
    (3,  'Knurling',               16, NULL),
    (4,  'Bending - U-Bend',      15, NULL),
    (5,  'Bending - Final',       30, NULL),
    (6,  'Gauging',               30, NULL),
    (7,  'Drain Hole I',          16, NULL),
    (8,  'Drilling II',           16, NULL),
    (9,  'Drilling LHS',          16, NULL),
    (10, 'Drilling RHS',          16, NULL),
    (11, 'Drill 3.5 M/M',         20, NULL),
    (12, 'Side Drill LHS',        16, NULL),
    (13, 'Side Drill RHS',        16, NULL),
    (14, 'Gauging',               20, NULL),
    (15, 'Laser Marking LHS',     20, NULL),
    (16, 'Laser Marking RHS',     20, NULL),
    (17, 'Laser Marking Centre',  20, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'H-100' AND b.item_name = 'Tube';

-- ===== N-40 : Tube (7 ops) =====
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Stamping',      10, NULL),
    (2, 'Knurling',      16, NULL),
    (3, 'Bending',       42, NULL),
    (4, 'Drilling LHS',  32, NULL),
    (5, 'Drilling RHS',  32, NULL),
    (6, 'Burr Removal',  20, NULL),
    (7, 'Marking RHS',   18, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'N-40' AND b.item_name = 'Tube';

-- ===== U-349C : Tube (7 ops) =====
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Stamping',       10, NULL),
    (2, 'Knurling',       16, NULL),
    (3, 'Bending',        42, NULL),
    (4, 'Drilling LHS',   16, NULL),
    (5, 'Drilling RHS',   16, NULL),
    (6, 'Burr Removal',   16, NULL),
    (7, 'Marking Centre', 18, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'U-349C' AND b.item_name = 'Tube';

-- ===== U-143 : Tube (7 ops) =====
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Stamping',       10, NULL),
    (2, 'Knurling',       16, NULL),
    (3, 'Bending',        42, NULL),
    (4, 'Drilling LHS',   32, NULL),
    (5, 'Drilling RHS',   32, NULL),
    (6, 'Burr Removal',   20, NULL),
    (7, 'Marking Centre', 18, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'U-143' AND b.item_name = 'Tube';

-- Long Bush {part} items intentionally get NO operations (BOP)

-- ============================================================
-- END
-- ============================================================
