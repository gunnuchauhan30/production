-- ============================================================
-- Chanda PPC — Master Data Seed: Handle Bar Notebook Sheets (07/09/26)
-- Source: 3 handwritten notebook photos, each listing a group of part
-- numbers that share the same routing (operation + cycle time +
-- machine code). Transcribed and applied 2026-09-07.
--
-- IMPORTANT: "U-349C" here is a DIFFERENT literal part_number from the
-- "HB-349C" entered earlier via the UI (which still has blank cycle
-- times). They look like the same physical part written two ways —
-- worth cleaning up by hand so the system doesn't carry two entries
-- for one part.
--
-- Requires v2.4 addon (machine_no column) to already be applied.
-- Idempotent: safe to re-run.
--
-- Apply with (PowerShell):
--   Get-Content master_data_seed_notebook_07sep26.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

INSERT INTO part_routing (part_number, operation_name, operation_seq, cycle_time_sec, machine_no) VALUES

-- ===== H-100 =====
('H-100', 'Stamping + Knurling', 1, 42, 'KM-02'),
('H-100', 'Bending - U-Bend', 2, 16, 'BM-01'),
('H-100', 'Bending - Final', 3, 32, 'BM-05'),
('H-100', 'Drilling', 4, 16, 'DM-01,02,03'),
('H-100', 'Gauging', 5, 20, NULL),
('H-100', 'Buffing', 6, 71, 'GM-02'),
('H-100', 'For Paint', 7, NULL, NULL),
('H-100', 'Laser Marking', 8, 45, NULL),

-- ===== D3K =====
('D3K', 'Stamping + Knurling', 1, 26, 'KM-01'),
('D3K', 'Bending', 2, 25, 'BM-01'),
('D3K', 'Bush Drill', 3, 21, 'DM-05'),
('D3K', 'Reamer', 4, 38, 'DM-06'),
('D3K', 'Welding', 5, 70, 'MW-11'),
('D3K', 'Drilling', 6, 16, 'DM-01,02,03'),
('D3K', 'Marking', 7, 18, NULL),
('D3K', 'Gauging', 8, 20, NULL),

-- ===== U-4D (same routing as D3K) =====
('U-4D', 'Stamping + Knurling', 1, 26, 'KM-01'),
('U-4D', 'Bending', 2, 25, 'BM-01'),
('U-4D', 'Bush Drill', 3, 21, 'DM-05'),
('U-4D', 'Reamer', 4, 38, 'DM-06'),
('U-4D', 'Welding', 5, 70, 'MW-11'),
('U-4D', 'Drilling', 6, 16, 'DM-01,02,03'),
('U-4D', 'Marking', 7, 18, NULL),
('U-4D', 'Gauging', 8, 20, NULL),

-- ===== C-550 (same routing as D3K) =====
('C-550', 'Stamping + Knurling', 1, 26, 'KM-01'),
('C-550', 'Bending', 2, 25, 'BM-01'),
('C-550', 'Bush Drill', 3, 21, 'DM-05'),
('C-550', 'Reamer', 4, 38, 'DM-06'),
('C-550', 'Welding', 5, 70, 'MW-11'),
('C-550', 'Drilling', 6, 16, 'DM-01,02,03'),
('C-550', 'Marking', 7, 18, NULL),
('C-550', 'Gauging', 8, 20, NULL),

-- ===== K00-2 =====
('K00-2', 'Stamping', 1, 10, 'STM-01'),
('K00-2', 'Knurling', 2, 10, 'KM-01'),
('K00-2', 'Bending', 3, 25, 'BM-01'),
('K00-2', 'Drilling', 4, 16, 'DM-01,02,03'),
('K00-2', 'Marking', 5, 18, NULL),
('K00-2', 'Bush Drill', 6, 21, 'DM-05'),
('K00-2', 'Reamer', 7, 38, 'DM-06'),
('K00-2', 'Welding', 8, 70, 'MW-12'),
('K00-2', 'Grinding', 9, 32, 'GM-01'),
('K00-2', 'Gauging', 10, 20, NULL),

-- ===== U-143 =====
('U-143', 'Stamping', 1, 10, 'STM-01'),
('U-143', 'Knurling', 2, 16, 'KM-01'),
('U-143', 'Bending', 3, 42, 'BM-02'),
('U-143', 'Drilling', 4, 16, 'DM-01,02'),
('U-143', 'Marking', 5, 18, 'PP'),
('U-143', 'For Painting', 6, NULL, NULL),
('U-143', 'Packing', 7, NULL, NULL),

-- ===== U-349C (same routing as U-143) =====
('U-349C', 'Stamping', 1, 10, 'STM-01'),
('U-349C', 'Knurling', 2, 16, 'KM-01'),
('U-349C', 'Bending', 3, 42, 'BM-02'),
('U-349C', 'Drilling', 4, 16, 'DM-01,02'),
('U-349C', 'Marking', 5, 18, 'PP'),
('U-349C', 'For Painting', 6, NULL, NULL),
('U-349C', 'Packing', 7, NULL, NULL),

-- ===== J1A =====
('J1A', 'Stamping + Knurling', 1, 26, 'KM-01'),
('J1A', 'Bending', 2, 25, 'BM-01'),
('J1A', 'Drilling', 3, 16, 'DM-01,02,03'),
('J1A', 'Marking', 4, 18, 'PP'),
('J1A', 'Bush Drill', 5, 21, 'DM-05'),
('J1A', 'Rimmer', 6, 38, 'DM-06'),
('J1A', 'Welding', 7, 70, 'MW-02'),
('J1A', 'Grinding', 8, 32, 'GM-01'),
('J1A', 'Gauging', 9, 20, NULL),

-- ===== J1C-5 (same routing as J1A) =====
('J1C-5', 'Stamping + Knurling', 1, 26, 'KM-01'),
('J1C-5', 'Bending', 2, 25, 'BM-01'),
('J1C-5', 'Drilling', 3, 16, 'DM-01,02,03'),
('J1C-5', 'Marking', 4, 18, 'PP'),
('J1C-5', 'Bush Drill', 5, 21, 'DM-05'),
('J1C-5', 'Rimmer', 6, 38, 'DM-06'),
('J1C-5', 'Welding', 7, 70, 'MW-02'),
('J1C-5', 'Grinding', 8, 32, 'GM-01'),
('J1C-5', 'Gauging', 9, 20, NULL),

-- ===== J1D1 (same routing as J1A) — NOTE: distinct from "H/B J1D1"
-- already seeded earlier with just one op (Gauging=20). Likely the
-- same part written two ways; worth reconciling by hand.
('J1D1', 'Stamping + Knurling', 1, 26, 'KM-01'),
('J1D1', 'Bending', 2, 25, 'BM-01'),
('J1D1', 'Drilling', 3, 16, 'DM-01,02,03'),
('J1D1', 'Marking', 4, 18, 'PP'),
('J1D1', 'Bush Drill', 5, 21, 'DM-05'),
('J1D1', 'Rimmer', 6, 38, 'DM-06'),
('J1D1', 'Welding', 7, 70, 'MW-02'),
('J1D1', 'Grinding', 8, 32, 'GM-01'),
('J1D1', 'Gauging', 9, 20, NULL),

-- ===== J1C-5 V-2 (same routing as J1A) =====
('J1C-5 V-2', 'Stamping + Knurling', 1, 26, 'KM-01'),
('J1C-5 V-2', 'Bending', 2, 25, 'BM-01'),
('J1C-5 V-2', 'Drilling', 3, 16, 'DM-01,02,03'),
('J1C-5 V-2', 'Marking', 4, 18, 'PP'),
('J1C-5 V-2', 'Bush Drill', 5, 21, 'DM-05'),
('J1C-5 V-2', 'Rimmer', 6, 38, 'DM-06'),
('J1C-5 V-2', 'Welding', 7, 70, 'MW-02'),
('J1C-5 V-2', 'Grinding', 8, 32, 'GM-01'),
('J1C-5 V-2', 'Gauging', 9, 20, NULL)

ON CONFLICT (part_number, operation_seq) DO UPDATE SET
    operation_name = EXCLUDED.operation_name,
    cycle_time_sec = EXCLUDED.cycle_time_sec,
    machine_no = EXCLUDED.machine_no;

-- ============================================================
-- END OF SEED — reconcile these by hand before your next production
-- run:
--   1. HB-349C  (old, blank cycle times)  vs  U-349C  (new, filled)
--   2. H/B J1D1 (old, one op: Gauging=20) vs  J1D1    (new, 9 ops)
-- ============================================================
