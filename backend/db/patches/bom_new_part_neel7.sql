-- ============================================================
-- Chanda PPC — New Part: Neel-7
-- BOM items: BR Pipe, AR Pipe (no Assembly, no Long Bush, per instruction)
-- Customer not given on this sheet -- left blank; set via Master Data
-- "Edit details" whenever known.
--
-- Apply with (PowerShell):
--   Get-Content bom_new_part_neel7.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

INSERT INTO parts (part_number, part_name, customer_name) VALUES ('Neel-7', 'Pipe', NULL)
ON CONFLICT (part_number) DO NOTHING;

INSERT INTO bom_items (part_number, item_name, spec, item_seq) VALUES
    ('Neel-7', 'BR Pipe', '13.05 X 1.4 X 315 MM', 1),
    ('Neel-7', 'AR Pipe', '19.05 X 1.4 X 225 MM', 2)
ON CONFLICT (part_number, item_name) DO UPDATE SET spec = EXCLUDED.spec, item_seq = EXCLUDED.item_seq;

DELETE FROM bom_operations WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number = 'Neel-7');

-- BR Pipe operations
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Bending',        20, NULL),
    (2, 'Forging',        12, NULL),
    (3, 'End Cutting',    12, NULL),
    (4, 'Radish Cutting', 22, NULL),
    (5, 'Chamfring',      15, NULL),
    (6, 'Drilling',       10, NULL),
    (7, 'Gauging',        15, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'Neel-7' AND b.item_name = 'BR Pipe';

-- AR Pipe operations
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Insert Pipe', 20, NULL),
    (2, 'Bending',      20, NULL),
    (3, 'Forging',      12, NULL),
    (4, 'Punching',     15, NULL),
    (5, 'Sizing',       15, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'Neel-7' AND b.item_name = 'AR Pipe';

-- ============================================================
-- END
-- ============================================================
