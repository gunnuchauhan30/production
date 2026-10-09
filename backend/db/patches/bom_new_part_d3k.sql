-- ============================================================
-- Chanda PPC — New Part: Handle Bar D3K (Customer: VARROC)
-- Structure: Tube / Long Bush D3K (BOP, no ops) / Assembly
-- Tube spec left blank -- wasn't given on this sheet; add it via
-- the Master Data screen (Edit) whenever you have it.
--
-- Apply with (PowerShell):
--   Get-Content bom_new_part_d3k.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

INSERT INTO parts (part_number, part_name, customer_name) VALUES ('D3K', 'Handle Bar', 'VARROC')
ON CONFLICT (part_number) DO UPDATE SET part_name = EXCLUDED.part_name, customer_name = EXCLUDED.customer_name;

INSERT INTO bom_items (part_number, item_name, spec, item_seq) VALUES
    ('D3K', 'Tube', NULL, 1),
    ('D3K', 'Long Bush D3K', 'BOP', 2),
    ('D3K', 'Assembly', NULL, 3)
ON CONFLICT (part_number, item_name) DO UPDATE SET spec = EXCLUDED.spec, item_seq = EXCLUDED.item_seq;

DELETE FROM bom_operations WHERE bom_item_id IN (SELECT id FROM bom_items WHERE part_number = 'D3K');

-- D3K : Tube operations
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1,  'Stamping',          10, NULL),
    (2,  'Knurling',          16, NULL),
    (3,  'Bending',           25, NULL),
    (4,  'Bush Drill',        21, NULL),
    (5,  'Rimmer',            38, NULL),
    (6,  'Drin Hole Drill',   32, NULL),
    (7,  'Drilling LHS',      16, NULL),
    (8,  'Drilling RHS',      16, NULL),
    (9,  'Burr Remove',       16, NULL),
    (10, 'Marking LHS',       18, NULL),
    (11, 'Marking Centre',    18, NULL),
    (12, 'Marking RHS-I',     18, NULL),
    (13, 'Marking RHS-II',    18, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'D3K' AND b.item_name = 'Tube';

-- D3K : Assembly operations
INSERT INTO bom_operations (bom_item_id, operation_seq, operation_name, cycle_time_sec, machine_no)
SELECT b.id, x.operation_seq, x.operation_name, x.cycle_time_sec, x.machine_no
FROM bom_items b
CROSS JOIN (VALUES
    (1, 'Welding',  70, NULL),
    (2, 'Grinding', 32, NULL),
    (3, 'Gauging',  20, NULL)
) AS x(operation_seq, operation_name, cycle_time_sec, machine_no)
WHERE b.part_number = 'D3K' AND b.item_name = 'Assembly';

-- Long Bush D3K intentionally gets NO operations (BOP)

-- ============================================================
-- END
-- ============================================================
