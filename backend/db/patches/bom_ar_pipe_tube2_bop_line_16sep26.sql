-- ============================================================
-- Chanda PPC -- AR Pipe "Tube 2": put BOP on its own line below
-- the dimensions (same style as the Grade line on the first Tube)
--
-- Apply with (PowerShell):
--   Get-Content bom_ar_pipe_tube2_bop_line_16sep26.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

UPDATE bom_items
SET spec = E'15.88 X 1.5 X 100 MM\nBOP'
WHERE part_number = 'AR Pipe' AND item_name = 'Tube 2';

-- in case it was renamed to plain "Tube" by an earlier manual edit
UPDATE bom_items
SET spec = E'15.88 X 1.5 X 100 MM\nBOP'
WHERE part_number = 'AR Pipe' AND spec ILIKE '%15.88%';

-- Verify
SELECT item_name, spec FROM bom_items WHERE part_number = 'AR Pipe' ORDER BY item_seq;

-- ============================================================
-- END
-- ============================================================
