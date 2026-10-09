-- ============================================================
-- Chanda PPC -- ADD: New Parts (same structure as Handle Bar J1A)
-- Parts: J1B, J1C, J1C2, J1C5, J1C5-1, J1C5-2, J1D1, V1F
--
-- For each part this creates the SAME structure as J1A:
--   Tube          (spec left BLANK -- fill exact size via 'Edit' in UI)
--   Long Bush X   (BOP -- no operations, same as J1A)
--   Assembly      (Welding 70s, Grinding 32s, Gauging 20s -- same as J1A)
--
-- part_name is set to 'Handle Bar' for the J1* parts (same family as J1A).
-- V1F is a different prefix -- part_name left blank, set it via 'Edit details' in UI.
--
-- Apply with (PowerShell):
--   Get-Content bom_add_new_parts_09sep26.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

-- ---------- J1B ----------
INSERT INTO parts (part_number, part_name) VALUES ('J1B', 'Handle Bar')
ON CONFLICT (part_number) DO NOTHING;

INSERT INTO bom_items (part_number, item_name, spec, item_seq) VALUES
    ('J1B', 'Tube', NULL, 1),
    ('J1B', 'Long Bush J1B', 'BOP', 2),
    ('J1B', 'Assembly', NULL, 3)
ON CONFLICT (part_number, item_name) DO NOTHING;

INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Welding',  70, NULL),
    (2, 'Grinding', 32, NULL),
    (3, 'Gauging',  20, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'J1B' AND b.item_name = 'Assembly'
ON CONFLICT (bom_item_id, operation_seq) DO NOTHING;

-- ---------- J1C ----------
INSERT INTO parts (part_number, part_name) VALUES ('J1C', 'Handle Bar')
ON CONFLICT (part_number) DO NOTHING;

INSERT INTO bom_items (part_number, item_name, spec, item_seq) VALUES
    ('J1C', 'Tube', NULL, 1),
    ('J1C', 'Long Bush J1C', 'BOP', 2),
    ('J1C', 'Assembly', NULL, 3)
ON CONFLICT (part_number, item_name) DO NOTHING;

INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Welding',  70, NULL),
    (2, 'Grinding', 32, NULL),
    (3, 'Gauging',  20, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'J1C' AND b.item_name = 'Assembly'
ON CONFLICT (bom_item_id, operation_seq) DO NOTHING;

-- ---------- J1C2 ----------
INSERT INTO parts (part_number, part_name) VALUES ('J1C2', 'Handle Bar')
ON CONFLICT (part_number) DO NOTHING;

INSERT INTO bom_items (part_number, item_name, spec, item_seq) VALUES
    ('J1C2', 'Tube', NULL, 1),
    ('J1C2', 'Long Bush J1C2', 'BOP', 2),
    ('J1C2', 'Assembly', NULL, 3)
ON CONFLICT (part_number, item_name) DO NOTHING;

INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Welding',  70, NULL),
    (2, 'Grinding', 32, NULL),
    (3, 'Gauging',  20, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'J1C2' AND b.item_name = 'Assembly'
ON CONFLICT (bom_item_id, operation_seq) DO NOTHING;

-- ---------- J1C5 ----------
INSERT INTO parts (part_number, part_name) VALUES ('J1C5', 'Handle Bar')
ON CONFLICT (part_number) DO NOTHING;

INSERT INTO bom_items (part_number, item_name, spec, item_seq) VALUES
    ('J1C5', 'Tube', NULL, 1),
    ('J1C5', 'Long Bush J1C5', 'BOP', 2),
    ('J1C5', 'Assembly', NULL, 3)
ON CONFLICT (part_number, item_name) DO NOTHING;

INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Welding',  70, NULL),
    (2, 'Grinding', 32, NULL),
    (3, 'Gauging',  20, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'J1C5' AND b.item_name = 'Assembly'
ON CONFLICT (bom_item_id, operation_seq) DO NOTHING;

-- ---------- J1C5-1 ----------
INSERT INTO parts (part_number, part_name) VALUES ('J1C5-1', 'Handle Bar')
ON CONFLICT (part_number) DO NOTHING;

INSERT INTO bom_items (part_number, item_name, spec, item_seq) VALUES
    ('J1C5-1', 'Tube', NULL, 1),
    ('J1C5-1', 'Long Bush J1C5-1', 'BOP', 2),
    ('J1C5-1', 'Assembly', NULL, 3)
ON CONFLICT (part_number, item_name) DO NOTHING;

INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Welding',  70, NULL),
    (2, 'Grinding', 32, NULL),
    (3, 'Gauging',  20, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'J1C5-1' AND b.item_name = 'Assembly'
ON CONFLICT (bom_item_id, operation_seq) DO NOTHING;

-- ---------- J1C5-2 ----------
INSERT INTO parts (part_number, part_name) VALUES ('J1C5-2', 'Handle Bar')
ON CONFLICT (part_number) DO NOTHING;

INSERT INTO bom_items (part_number, item_name, spec, item_seq) VALUES
    ('J1C5-2', 'Tube', NULL, 1),
    ('J1C5-2', 'Long Bush J1C5-2', 'BOP', 2),
    ('J1C5-2', 'Assembly', NULL, 3)
ON CONFLICT (part_number, item_name) DO NOTHING;

INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Welding',  70, NULL),
    (2, 'Grinding', 32, NULL),
    (3, 'Gauging',  20, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'J1C5-2' AND b.item_name = 'Assembly'
ON CONFLICT (bom_item_id, operation_seq) DO NOTHING;

-- ---------- J1D1 ----------
INSERT INTO parts (part_number, part_name) VALUES ('J1D1', 'Handle Bar')
ON CONFLICT (part_number) DO NOTHING;

INSERT INTO bom_items (part_number, item_name, spec, item_seq) VALUES
    ('J1D1', 'Tube', NULL, 1),
    ('J1D1', 'Long Bush J1D1', 'BOP', 2),
    ('J1D1', 'Assembly', NULL, 3)
ON CONFLICT (part_number, item_name) DO NOTHING;

INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Welding',  70, NULL),
    (2, 'Grinding', 32, NULL),
    (3, 'Gauging',  20, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'J1D1' AND b.item_name = 'Assembly'
ON CONFLICT (bom_item_id, operation_seq) DO NOTHING;

-- ---------- V1F ----------
INSERT INTO parts (part_number) VALUES ('V1F')
ON CONFLICT (part_number) DO NOTHING;

INSERT INTO bom_items (part_number, item_name, spec, item_seq) VALUES
    ('V1F', 'Tube', NULL, 1),
    ('V1F', 'Long Bush V1F', 'BOP', 2),
    ('V1F', 'Assembly', NULL, 3)
ON CONFLICT (part_number, item_name) DO NOTHING;

INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Welding',  70, NULL),
    (2, 'Grinding', 32, NULL),
    (3, 'Gauging',  20, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'V1F' AND b.item_name = 'Assembly'
ON CONFLICT (bom_item_id, operation_seq) DO NOTHING;

-- ============================================================
-- END
-- ============================================================
