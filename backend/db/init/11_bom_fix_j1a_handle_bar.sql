-- ============================================================
-- Chanda PPC — FIX: J1A Master Data (Handle Bar) — 09-Sep-2026
--
-- Requires ppe_schema_addon_v2.6_parts.sql to already be applied
-- (creates the `parts` table this script writes into).
--
-- What this does:
--   1. J1A is now labelled "Handle Bar" -> shows as "Handle Bar J1A"
--   2. "RM" BOM item renamed to "Tube", spec corrected to
--      22.2 X 2.0 X 841 MM (was wrongly 891)
--   3. "Long Bush" renamed to "Long Bush J1A" and marked as a
--      Bought-Out Part: spec becomes the literal text "BOP" and it
--      no longer carries any in-house operations
--   4. A new "Assembly" BOM item is created carrying the 3
--      operations that used to be wrongly duplicated on both
--      RM and Long Bush: Welding (70s), Grinding (32s), Gauging (20s)
--
-- Apply with (PowerShell), against the already-running database:
--   Get-Content bom_fix_j1a_handle_bar_09sep26.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

-- 1. Part display name: J1A -> "Handle Bar"
INSERT INTO parts (part_number, part_name) VALUES ('J1A', 'Handle Bar')
ON CONFLICT (part_number) DO UPDATE SET part_name = EXCLUDED.part_name;

-- 2. RM -> Tube, corrected spec
UPDATE bom_items
SET item_name = 'Tube',
    spec = '22.2 X 2.0 X 841 MM'
WHERE part_number = 'J1A' AND item_name = 'RM';

-- 3. Long Bush -> Long Bush J1A, marked as BOP (Bought-Out Part)
UPDATE bom_items
SET item_name = 'Long Bush J1A',
    spec = 'BOP'
WHERE part_number = 'J1A' AND item_name = 'Long Bush';

-- Long Bush is bought-in, not manufactured here -- it carries no operations
DELETE FROM bom_operations
WHERE bom_item_id IN (
    SELECT id FROM bom_items WHERE part_number = 'J1A' AND item_name = 'Long Bush J1A'
);

-- Also strip the Welding/Grinding/Gauging trio off Tube (ex-RM) -- those
-- are assembly-stage operations, not part of tube fabrication, and are
-- moved to the new "Assembly" BOM item below.
DELETE FROM bom_operations
WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number = 'J1A' AND item_name = 'Tube')
  AND operation_name IN ('Welding', 'Grinding', 'Gauging');

-- 4. New "Assembly" BOM item with the 3 assembly operations
INSERT INTO bom_items (part_number, item_name, spec, item_seq)
VALUES ('J1A', 'Assembly', NULL, 3)
ON CONFLICT (part_number, item_name) DO NOTHING;

INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Welding',  70, NULL),
    (2, 'Grinding', 32, NULL),
    (3, 'Gauging',  20, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'J1A' AND b.item_name = 'Assembly'
ON CONFLICT (bom_item_id, operation_seq) DO UPDATE SET
    operation_name = EXCLUDED.operation_name,
    cycle_time_sec = EXCLUDED.cycle_time_sec;

-- ============================================================
-- END OF FIX
-- ============================================================
