-- ============================================================
-- Chanda PPC — New Parts: Handle Bar C-350, Handle Bar U4D (Customer: VARROC)
-- Structure: Tube / Long Bush {PART} (BOP, no ops) / Assembly
--
-- Apply with (PowerShell):
--   Get-Content bom_new_parts_c350_u4d.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

INSERT INTO parts (part_number, part_name, customer_name) VALUES
    ('C-350', 'Handle Bar', 'VARROC'),
    ('U4D',   'Handle Bar', 'VARROC')
ON CONFLICT (part_number) DO UPDATE SET part_name = EXCLUDED.part_name, customer_name = EXCLUDED.customer_name;

INSERT INTO bom_items (part_number, item_name, spec, item_seq) VALUES
    ('C-350', 'Tube',              '22.2 X 2 X 788 MM', 1),
    ('C-350', 'Long Bush C-350',   'BOP',                2),
    ('C-350', 'Assembly',          NULL,                 3),
    ('U4D',   'Tube',              '22.2 X 2 X 887 MM', 1),
    ('U4D',   'Long Bush U4D',     'BOP',                2),
    ('U4D',   'Assembly',          NULL,                 3)
ON CONFLICT (part_number, item_name) DO UPDATE SET spec = EXCLUDED.spec, item_seq = EXCLUDED.item_seq;

DELETE FROM bom_operations WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number IN ('C-350', 'U4D'));

-- ===== C-350 : Tube =====
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1,  'Stamping',              10, NULL),
    (2,  'Knurling',              16, NULL),
    (3,  'Bending',               25, NULL),
    (4,  'Bush Drill',            21, NULL),
    (5,  'Reamer',                38, NULL),
    (6,  'Drin Hole',             16, NULL),
    (7,  'Drilling LHS',          16, NULL),
    (8,  'Drilling RHS',          16, NULL),
    (9,  'Burr Removal',          16, NULL),
    (10, 'Marking LHS',           18, NULL),
    (11, 'Marking RHS Cutting',   18, NULL),
    (12, 'Marking RHS',           18, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'C-350' AND b.item_name = 'Tube';

-- ===== C-350 : Assembly =====
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Welding',  70, NULL),
    (2, 'Grinding', 32, NULL),
    (3, 'Gauging',  20, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'C-350' AND b.item_name = 'Assembly';

-- ===== U4D : Tube =====
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1,  'Stamping',              10, NULL),
    (2,  'Knurling',              16, NULL),
    (3,  'Bending',               25, NULL),
    (4,  'Bush Drill',            21, NULL),
    (5,  'Reamer',                38, NULL),
    (6,  'Drilling LHS',          16, NULL),
    (7,  'Drilling RHS',          16, NULL),
    (8,  'Burr Removal',          16, NULL),
    (9,  'Marking LHS',           18, NULL),
    (10, 'Marking Centre I',      18, NULL),
    (11, 'Marking Centre II',     18, NULL),
    (12, 'Marking RHS',           18, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'U4D' AND b.item_name = 'Tube';

-- ===== U4D : Assembly =====
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Welding',  70, NULL),
    (2, 'Grinding', 32, NULL),
    (3, 'Gauging',  20, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'U4D' AND b.item_name = 'Assembly';

-- Long Bush C-350 / Long Bush U4D intentionally get NO operations (BOP)

-- ============================================================
-- END
-- ============================================================
