-- ============================================================
-- Chanda PPC -- RESTRUCTURE: Housing Cat Assembly
-- 'Tacking' and 'Welding' become their own BOM items (like Tube),
-- each listing the 5 components it applies to, with cycle time.
-- Also (re)fixes ops for 189mm/109mm/68mm Pipe + Baffle-2, in case
-- the earlier fix script wasn't run yet -- safe either way.
-- 15-Sep-2026
--
-- Apply with (PowerShell):
--   Get-Content bom_housing_cat_tacking_welding_15sep26.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

-- Remove old top-level 'End Plug' item if it still exists
DELETE FROM bom_operations WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number = 'Housing Cat' AND item_name = 'End Plug');
DELETE FROM bom_items WHERE part_number = 'Housing Cat' AND item_name = 'End Plug';

-- Remove old 'Assembly' item (Tacking/Welding move out to be their own items)
DELETE FROM bom_operations WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number = 'Housing Cat' AND item_name = 'Assembly');
DELETE FROM bom_items WHERE part_number = 'Housing Cat' AND item_name = 'Assembly';

-- Housing Cat : 189mm Pipe
DELETE FROM bom_operations WHERE bom_item_id = (SELECT id FROM bom_items WHERE part_number = 'Housing Cat' AND item_name = '189mm Pipe');
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Flaring', NULL::numeric, NULL::varchar),
    (2, 'Punching', NULL::numeric, NULL::varchar)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'Housing Cat' AND b.item_name = '189mm Pipe';

-- Housing Cat : 109mm Pipe
DELETE FROM bom_operations WHERE bom_item_id = (SELECT id FROM bom_items WHERE part_number = 'Housing Cat' AND item_name = '109mm Pipe');
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Flaring', NULL::numeric, NULL::varchar),
    (2, 'Punching', NULL::numeric, NULL::varchar)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'Housing Cat' AND b.item_name = '109mm Pipe';

-- Housing Cat : 68mm Pipe
DELETE FROM bom_operations WHERE bom_item_id = (SELECT id FROM bom_items WHERE part_number = 'Housing Cat' AND item_name = '68mm Pipe');
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Flaring', NULL::numeric, NULL::varchar),
    (2, 'Punching-I', NULL::numeric, NULL::varchar),
    (3, 'Punching-II', NULL::numeric, NULL::varchar),
    (4, 'Notching', NULL::numeric, NULL::varchar)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'Housing Cat' AND b.item_name = '68mm Pipe';

-- Housing Cat : Baffle-2
DELETE FROM bom_operations WHERE bom_item_id = (SELECT id FROM bom_items WHERE part_number = 'Housing Cat' AND item_name = 'Baffle-2');
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Sharing', NULL::numeric, NULL::varchar),
    (2, 'Blank', NULL::numeric, NULL::varchar),
    (3, 'Draw', NULL::numeric, NULL::varchar),
    (4, 'Punching+Notching', NULL::numeric, NULL::varchar),
    (5, 'Flaring', NULL::numeric, NULL::varchar)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'Housing Cat' AND b.item_name = 'Baffle-2';

-- New BOM items: Tacking, Welding
INSERT INTO bom_items (part_number, item_name, spec, item_seq) VALUES
    ('Housing Cat', 'Tacking', NULL, 6),
    ('Housing Cat', 'Welding', NULL, 7)
ON CONFLICT (part_number, item_name) DO UPDATE SET spec = EXCLUDED.spec, item_seq = EXCLUDED.item_seq;

-- Housing Cat : Tacking -- 5 components, 48 sec each
DELETE FROM bom_operations WHERE bom_item_id = (SELECT id FROM bom_items WHERE part_number = 'Housing Cat' AND item_name = 'Tacking');
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Baffle-2', 48, NULL::varchar),
    (2, '189mm Pipe', 48, NULL::varchar),
    (3, '68mm Pipe', 48, NULL::varchar),
    (4, '109mm Pipe', 48, NULL::varchar),
    (5, 'End Plug', 48, NULL::varchar)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'Housing Cat' AND b.item_name = 'Tacking';

-- Housing Cat : Welding -- 5 components, 37.6 sec each
DELETE FROM bom_operations WHERE bom_item_id = (SELECT id FROM bom_items WHERE part_number = 'Housing Cat' AND item_name = 'Welding');
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Baffle-2', 37.6, NULL::varchar),
    (2, '189mm Pipe', 37.6, NULL::varchar),
    (3, '68mm Pipe', 37.6, NULL::varchar),
    (4, '109mm Pipe', 37.6, NULL::varchar),
    (5, 'End Plug', 37.6, NULL::varchar)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'Housing Cat' AND b.item_name = 'Welding';

-- ============================================================
-- Verify: should show 189mm Pipe, 109mm Pipe, 68mm Pipe, Baffle-2,
-- Housing Bush, Tacking, Welding (7 items, no Assembly, no End Plug)
SELECT item_name, spec, item_seq FROM bom_items WHERE part_number = 'Housing Cat' ORDER BY item_seq;
-- ============================================================
