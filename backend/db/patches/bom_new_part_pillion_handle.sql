-- ============================================================
-- Chanda PPC — New Part: Pillion Handle
-- BOM items: Tube, Patti, UBKT, BOP (Nuts), Assembly
--
-- Apply with (PowerShell):
--   Get-Content bom_new_part_pillion_handle.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

INSERT INTO parts (part_number, part_name, customer_name) VALUES ('Pillion Handle', 'Pillion Handle', NULL)
ON CONFLICT (part_number) DO NOTHING;

INSERT INTO bom_items (part_number, item_name, spec, grade, item_seq) VALUES
    ('Pillion Handle', 'Tube',        '271 X 1250 X 2.0 MM', 'HROP', 1),
    ('Pillion Handle', 'Patti',       '43 X 1250 X 2.0 MM',  'HROP', 2),
    ('Pillion Handle', 'UBKT',        '32 X 1.5 MM',         'HROP', 3),
    ('Pillion Handle', 'BOP (Nuts)',  'M-8 NUT x4, M-6 NUT x1', NULL, 4),
    ('Pillion Handle', 'Assembly',    NULL,                   NULL, 5)
ON CONFLICT (part_number, item_name) DO UPDATE SET spec = EXCLUDED.spec, grade = EXCLUDED.grade, item_seq = EXCLUDED.item_seq;

DELETE FROM bom_operations WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number = 'Pillion Handle');

-- Tube operations
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec::numeric, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Shearing',     NULL, NULL),
    (2, 'Blank',        NULL, NULL),
    (3, 'Draw',         NULL, NULL),
    (4, 'Punching-I',   NULL, NULL),
    (5, 'Punching-II',  NULL, NULL),
    (6, 'Punching-III', NULL, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'Pillion Handle' AND b.item_name = 'Tube';

-- Patti operations
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec::numeric, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Shearing',        NULL, NULL),
    (2, 'Blank/Punching',  NULL, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'Pillion Handle' AND b.item_name = 'Patti';

-- UBKT operations
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec::numeric, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Shearing', NULL, NULL),
    (2, 'Blank',    NULL, NULL),
    (3, 'Bending',  NULL, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'Pillion Handle' AND b.item_name = 'UBKT';

-- Assembly operations
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec::numeric, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Tacking - BKT',   29,    NULL),
    (2, 'Tacking - Patti', 15.6,  NULL),
    (3, 'Tacking - Nut',   6.8,   NULL),
    (4, 'Welding',         40.64, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'Pillion Handle' AND b.item_name = 'Assembly';

-- ============================================================
-- END
-- ============================================================
