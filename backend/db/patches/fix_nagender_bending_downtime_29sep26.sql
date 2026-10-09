-- ============================================================
-- Chanda PPC -- Fix test entry: Down Time 65 -> 50 (Nagender, Bending, J1A, 29-Sep-2026)
--
-- Recomputes Run Time / Availability / Performance / OEE from the row's own
-- stored Total Time, Produced Qty and Standard Cycle Time -- doesn't
-- guess any numbers.
--
-- Apply with (PowerShell):
--   Get-Content fix_nagender_bending_downtime_29sep26.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

UPDATE production_log_entries
SET down_time_min = 50,
    run_time_min = (total_time_min - 50),
    availability = ROUND((total_time_min - 50) / total_time_min, 5),
    performance = ROUND((standard_cycle_time_sec * produced_qty) / ((total_time_min - 50) * 60), 5),
    oee = ROUND(
        ((total_time_min - 50) / total_time_min)
        * ((standard_cycle_time_sec * produced_qty) / ((total_time_min - 50) * 60))
        * COALESCE(quality, 1),
        5
    )
WHERE part_number = 'J1A'
  AND operation_name ILIKE 'Bending'
  AND operator_name ILIKE 'Nagender'
  AND entry_date = '2026-09-29';

-- Verify
SELECT entry_date, part_number, operation_name, operator_name, total_time_min,
       down_time_min, run_time_min, availability, performance, quality, oee
FROM production_log_entries
WHERE part_number = 'J1A' AND operation_name ILIKE 'Bending' AND operator_name ILIKE 'Nagender' AND entry_date = '2026-09-29';

-- ============================================================
-- END
-- ============================================================
