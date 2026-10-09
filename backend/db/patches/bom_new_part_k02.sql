-- ============================================================
-- Chanda PPC — New Part: Handle Bar K0-2 (Customer: MINDA)
-- Structure: Tube (ALL 17 ops, including Welding/Grinding/Gauging) +
-- Long Bush K0-2 (BOP, no ops). NO separate Assembly item, per
-- instruction to skip Assembly on every part going forward.
--
-- Apply with (PowerShell):
--   Get-Content bom_new_part_k02.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

INSERT INTO parts (part_number, part_name, customer_name) VALUES ('K0-2', 'Handle Bar', 'MINDA')
ON CONFLICT (part_number) DO UPDATE SET part_name = EXCLUDED.part_name, customer_name = EXCLUDED.customer_name;

INSERT INTO bom_items (part_number, item_name, spec, item_seq) VALUES
    ('K0-2', 'Tube',            '22.2 X 2 X 874 MM', 1),
    ('K0-2', 'Long Bush K0-2',  'BOP',                2)
ON CONFLICT (part_number, item_name) DO UPDATE SET spec = EXCLUDED.spec, item_seq = EXCLUDED.item_seq;

DELETE FROM bom_operations WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number = 'K0-2');

INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1,  'Centerless',       50, NULL),
    (2,  'Stamping',         10, NULL),
    (3,  'Knurling',         20, NULL),
    (4,  'Bending',          25, NULL),
    (5,  'Drain Hole',       16, NULL),
    (6,  'Drilling LHS',     16, NULL),
    (7,  'Drilling RHS',     16, NULL),
    (8,  'Drill 3.5 MM',     20, NULL),
    (9,  'Burr Remove',      16, NULL),
    (10, 'Marking LHS',      18, NULL),
    (11, 'Marking RHS',      18, NULL),
    (12, 'Marking Centre',   18, NULL),
    (13, 'Bush Drill',       21, NULL),
    (14, 'Rimmer',           38, NULL),
    (15, 'Welding',          70, NULL),
    (16, 'Grinding',         42, NULL),
    (17, 'Gauging',          20, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'K0-2' AND b.item_name = 'Tube';

-- Long Bush K0-2 intentionally gets NO operations (BOP)

-- ============================================================
-- END
-- ============================================================
