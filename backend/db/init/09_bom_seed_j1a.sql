-- ============================================================
-- Chanda PPC — BOM Seed: Handle Bar J1A (Customer: Honda/Yamaha)
-- Final corrected version — both RM and Long Bush carry the SAME
-- full 14-operation list, numbered exactly as confirmed.
--
-- Apply with (PowerShell):
--   Get-Content bom_seed_j1a.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

INSERT INTO bom_items (part_number, item_name, spec, item_seq) VALUES
    ('J1A', 'RM', '22.2 X 2.0 X 891 MM', 1),
    ('J1A', 'Long Bush', '19.05 X 130 MM', 2)
ON CONFLICT (part_number, item_name) DO UPDATE SET spec = EXCLUDED.spec;

DELETE FROM bom_operations
WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number = 'J1A');

INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1,  'Stamping',             10, NULL),
    (2,  'Knurling',             16, NULL),
    (3,  'Bending',              25, NULL),
    (4,  'Bush Drill - 105MM',   16, NULL),
    (5,  'Drilling LHS',         16, NULL),
    (6,  'Drilling RHS',         16, NULL),
    (7,  'Burr Remove',          16, NULL),
    (8,  'Center Marking',       18, NULL),
    (9,  'RHS Side Marking',     18, NULL),
    (10, 'Bush Drill',           21, NULL),
    (11, 'Reamer',               38, NULL),
    (12, 'Welding',              70, NULL),
    (13, 'Grinding',             32, NULL),
    (14, 'Gauging',              20, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'J1A';

-- ============================================================
-- END OF SEED
-- ============================================================
