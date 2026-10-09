-- ============================================================
-- Chanda PPC — New Part: Housing Cat (Customer: NAPL Nalagarh)
-- BOM items: 189mm Pipe, 109mm Pipe, 68mm Pipe, Baffle-2, Assembly
-- (Housing Bush intentionally excluded; End Plug excluded -- spec/ops
-- not confirmed yet, add later if needed.)
--
-- Apply with (PowerShell):
--   Get-Content bom_new_part_housingcat.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

INSERT INTO parts (part_number, part_name, customer_name) VALUES ('Housing Cat', 'Housing', 'NAPL Nalagarh')
ON CONFLICT (part_number) DO UPDATE SET part_name = EXCLUDED.part_name, customer_name = EXCLUDED.customer_name;

INSERT INTO bom_items (part_number, item_name, spec, item_seq) VALUES
    ('Housing Cat', '189mm Pipe', '50.8 X 1.2 X 189 MM', 1),
    ('Housing Cat', '109mm Pipe', '28.6 X 1.5 X 109 MM', 2),
    ('Housing Cat', '68mm Pipe',  '28.6 X 1.5 X 68 MM',  3),
    ('Housing Cat', 'Baffle-2',   '105 X 1.2 MM',        4),
    ('Housing Cat', 'Assembly',   NULL,                   5)
ON CONFLICT (part_number, item_name) DO UPDATE SET spec = EXCLUDED.spec, item_seq = EXCLUDED.item_seq;

DELETE FROM bom_operations WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number = 'Housing Cat');

-- 189mm Pipe
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Flaring',  NULL, NULL),
    (2, 'Punching', NULL, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'Housing Cat' AND b.item_name = '189mm Pipe';

-- 109mm Pipe
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Flaring',  NULL, NULL),
    (2, 'Punching', NULL, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'Housing Cat' AND b.item_name = '109mm Pipe';

-- 68mm Pipe
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Flaring',      NULL, NULL),
    (2, 'Punching-I',   NULL, NULL),
    (3, 'Punching-II',  NULL, NULL),
    (4, 'Notching',     NULL, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'Housing Cat' AND b.item_name = '68mm Pipe';

-- Baffle-2
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Shearing',              NULL, NULL),
    (2, 'Blank',                 NULL, NULL),
    (3, 'Draw',                  NULL, NULL),
    (4, 'Punching + Notching',   NULL, NULL),
    (5, 'Flaring',               NULL, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'Housing Cat' AND b.item_name = 'Baffle-2';

-- Assembly (totals across all 5 sub-components combined)
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Tacking', 48,   NULL),
    (2, 'Welding', 37.6, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'Housing Cat' AND b.item_name = 'Assembly';

-- ============================================================
-- END
-- ============================================================
