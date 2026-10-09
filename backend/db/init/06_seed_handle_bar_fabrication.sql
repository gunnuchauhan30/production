-- ============================================================
-- Chanda PPC — Master Data Seed: Part Routing + Standard Cycle Time
-- Source: "Handle Bar Department" sheet + "Fabrication Cycle Time" sheet
--         (photographed sheets, transcribed and confirmed 2026-09-07)
--
-- Only rows that were unambiguous are included here (a part name, an
-- operation, and a numeric cycle time all clearly readable). Rows that
-- were excluded, and why, are listed at the bottom of this file --
-- re-check those against the originals before adding them by hand.
--
-- Idempotent: re-running this is safe. Requires the v2.3 addon
-- (cycle_time_sec column) to already be applied.
--
-- Apply with:
--   psql -h localhost -U ppe_user -d chanda_ppe -f master_data_seed_handle_bar_fabrication.sql
-- or, if using Docker:
--   docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe < master_data_seed_handle_bar_fabrication.sql
-- ============================================================

INSERT INTO part_routing (part_number, operation_name, operation_seq, cycle_time_sec) VALUES
-- ALL HANDLE
('ALL HANDLE', 'Bending', 1, 25),
('ALL HANDLE', 'Knurling', 2, 16),
('ALL HANDLE', 'Mtg. Hole Drilling', 3, 16),
('ALL HANDLE', 'Data Stamping', 4, 10),
('ALL HANDLE', 'Bush Drill', 5, 21),

-- FRONT PIPE (Handle Bar dept ops 1-3, Fabrication dept op 4)
('FRONT PIPE', 'Bending', 1, 33),
('FRONT PIPE', 'Champring', 2, 10),
('FRONT PIPE', 'Cutting', 3, 16),
('FRONT PIPE', 'Welding', 4, 39.6),

-- BR PIPE (duplicate "Bending 20" row on the sheet collapsed to one entry, per confirmation)
('BR PIPE', 'Bending', 1, 20),
('BR PIPE', 'Drilling / BR', 2, 16),
('BR PIPE', 'Cutting', 3, 12),

-- BREATHER PIPE (YBP)
('BREATHER PIPE (YBP)', 'Bending', 1, 37),
('BREATHER PIPE (YBP)', 'Swaging', 2, 19),

-- LONG BUSH RE HANDLE
('LONG BUSH RE HANDLE', 'Bush Welding Grinding', 1, 34),
('LONG BUSH RE HANDLE', 'Bush Welding Tacking', 2, 34),
('LONG BUSH RE HANDLE', 'Bush Welding Final', 3, 35),

-- PIPE (AR)
('PIPE (AR)', 'Radius Cutting', 1, 24),
('PIPE (AR)', 'Champring', 2, 16),
('PIPE (AR)', 'Gauging', 3, 15),

-- PIPE (BR)  -- NOTE: sheet also has a separate "(BR) Pipe" row (Champring, 15)
-- kept as its own part_number below since exact spelling was confirmed to matter;
-- verify these two aren't meant to be the same part.
('PIPE (BR)', 'Radius Cutting', 1, 22),

('(BR) PIPE', 'Champring', 1, 15),

-- CAT EXTENDER
('CAT EXTENDER', 'Champring', 1, 14),
('CAT EXTENDER', 'Cutting', 2, 34),

-- H/B J1D1
('H/B J1D1', 'Gauging', 1, 20),

-- GLOSSY BLACK (Buffing line)
('GLOSSY BLACK', 'Jia Rim - Grinding', 1, 70),
('GLOSSY BLACK', 'Jia Rim - Flap Wheel', 2, 30),
('GLOSSY BLACK', 'Jia Rim Matt Wheel', 3, 20),

-- CROMA (Buffing line)
('CROMA', 'J1A, J1D3 Grinding', 1, 51),

-- P5AB, J1A CAP (Buffing Cap line)
('P5AB,J1A CAP', 'Grinding', 1, 13),
('P5AB,J1A CAP', 'Matt Wheel', 2, 24),
('P5AB,J1A CAP', 'Jute Buff Wheel', 3, 18),
('P5AB,J1A CAP', 'Cotton Buff Wheel', 4, 14),

-- GUSSET FRAME LH/RH
('GUSSET FRAME LH/RH', 'Pin Taking', 1, 30.4),

-- GUSSET FRAME LH
('GUSSET FRAME LH', 'Taking', 1, 49),
('GUSSET FRAME LH', 'Welding', 2, 86),

-- GUSSET FRAME RH
('GUSSET FRAME RH', 'Taking', 1, 27.6),
('GUSSET FRAME RH', 'Welding', 2, 56),

-- PILLION HANDLE SEAT LANCH (PATTI)
('PILLION HANDLE SEAT LANCH (PATTI)', 'Taking', 1, 15.6),

-- PILLION HANDLE NUT
('PILLION HANDLE NUT', 'Taking', 1, 6.8),

-- PILLION HANDLE UBKT
('PILLION HANDLE UBKT', 'Taking', 1, 29),
('PILLION HANDLE UBKT', 'Welding', 2, 40.6),

-- END CAP
('END CAP', 'Welding', 1, 30.6),

-- HOUSING
('HOUSING', 'Taking', 1, 48),
('HOUSING', 'Welding', 2, 37.6),

-- PRE-CAT
('PRE-CAT', 'Taking', 1, 16),
('PRE-CAT', 'Welding', 2, 28.2)

ON CONFLICT (part_number, operation_seq) DO UPDATE SET
    operation_name = EXCLUDED.operation_name,
    cycle_time_sec = EXCLUDED.cycle_time_sec;

-- ============================================================
-- EXCLUDED ROWS (need a decision or a clearer look at the original
-- before they can be inserted):
--
-- Sheet 1 (Handle Bar Department) -- no part name given on the sheet:
--   Welding                70 sec
--   Granding (Grinding)    32 sec
--   Knurling+Stamping      26 sec
--   Reamer                 38 sec
--
-- Sheet 1 -- handwritten margin notes, unclear which part/operation
-- row they attach to:
--   "Cat + Extendra (ID+OD) = 10"
--   "Bending CNC (BM01) = 25 / (BM002) = 42"   (looks machine-specific,
--       i.e. same operation, two different cycle times per machine --
--       part_routing has no machine dimension right now)
--   "operation Buffing+Polish +(12i)" / "Part -> (RIM P5AB)"
--
-- Sheet 2 (Fabrication) -- skipped per your instruction (blank cycle
-- time on the sheet):
--   Pillion Handle          -- Nut Spot M8,M6
--   4 Hole BKT              -- Nut Spot M8,M6
--   Rim J1A                 -- BKT Spot
--   YHB                     -- BKT Spot
--   Handle J1A              -- Bush Weld
--   (+ 3 further repeated rows with blank cycle time)
--
-- Sheet 2 -- excluded because which column is the part vs. the
-- operation is genuinely unclear from the sheet's layout:
--   "BKT Spot / J1D3"            42.6 sec
--   "BKT 2 Hole (Spot)"          5 sec
--   "BKT 4 Hole (Spot)"          8 sec
--   "BKT 2 Hole -- Nut Welding Taking"   8.4 sec
--   "BKT 4 Hole -- Nut Welding Taking"   7.8 sec
--   "Rim J1D3 -- BKT Spot"       42.6 sec
--   "Housing Cat -- Welding"     30 sec
--
-- Sheet 2 -- handwritten corrections at the bottom, not clearly tied
-- to a specific row above:
--   "Pillion Handle -> Taking -> 31.5"
--   "Handle J1A -> Bush Weld ->"          (no value written)
--   "Front Pipe -> Bending & Gauging ->"  (no value written)
--   "Housing Cat -> Taking -> 60"
-- ============================================================
