-- ============================================================
-- Chanda PPC — Housing Cat updates
-- 1. Add End Plug (41 X 1250 X 1.2 MM): Shearing, Blank, Draw
--    -- no cycle time, machine = Power Press
-- 2. Backfill machine = "Power Press" on every existing Housing Cat
--    operation that has no cycle time (Housing Pipe / Perforated Pipe
--    / Perforated Sheet / Baffle-2 ops)
-- 3. Merge "Assembly Tacking" + "Assembly Welding" (separate items)
--    back into ONE item "Assembly", holding both operations: each
--    listed per component (4 rows) then a Total row.
--
-- NOTE: This does NOT touch the item_name/spec of Housing Pipe,
-- Perforated Pipe, Perforated Sheet or Baffle-2 -- those were already
-- renamed/edited by hand and are left as-is.
--
-- Apply with (PowerShell):
--   Get-Content bom_housingcat_updates.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

-- 1. End Plug
INSERT INTO bom_items (part_number, item_name, spec, item_seq) VALUES
    ('Housing Cat', 'End Plug', '41 X 1250 X 1.2 MM', 6)
ON CONFLICT (part_number, item_name) DO UPDATE SET spec = EXCLUDED.spec;

DELETE FROM bom_operations WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number = 'Housing Cat' AND item_name = 'End Plug');

INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Shearing', NULL, 'Power Press'),
    (2, 'Blank',    NULL, 'Power Press'),
    (3, 'Draw',     NULL, 'Power Press')
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'Housing Cat' AND b.item_name = 'End Plug';

-- 2. Backfill machine = Power Press wherever cycle time is missing,
--    across all Housing Cat items
UPDATE bom_operations
SET machine_no = 'Power Press'
WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number = 'Housing Cat')
  AND cycle_time_sec IS NULL;

-- 3. Merge Assembly Tacking / Assembly Welding into one "Assembly" item
DELETE FROM bom_operations
WHERE bom_item_id IN (
    SELECT id FROM bom_items WHERE part_number = 'Housing Cat' AND item_name IN ('Assembly Tacking', 'Assembly Welding')
);
DELETE FROM bom_items
WHERE part_number = 'Housing Cat' AND item_name IN ('Assembly Tacking', 'Assembly Welding');

INSERT INTO bom_items (part_number, item_name, spec, item_seq) VALUES
    ('Housing Cat', 'Assembly', NULL, 7)
ON CONFLICT (part_number, item_name) DO NOTHING;

DELETE FROM bom_operations WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number = 'Housing Cat' AND item_name = 'Assembly');

INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1,  'Tacking - Housing Pipe',      NULL, NULL),
    (2,  'Tacking - Perforated Pipe',   NULL, NULL),
    (3,  'Tacking - Perforated Sheet',  NULL, NULL),
    (4,  'Tacking - Baffle-2',          NULL, NULL),
    (5,  'Tacking - Total',             48,   NULL),
    (6,  'Welding - Housing Pipe',      NULL, NULL),
    (7,  'Welding - Perforated Pipe',   NULL, NULL),
    (8,  'Welding - Perforated Sheet',  NULL, NULL),
    (9,  'Welding - Baffle-2',          NULL, NULL),
    (10, 'Welding - Total',             37.6, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'Housing Cat' AND b.item_name = 'Assembly';

-- ============================================================
-- END
-- ============================================================
