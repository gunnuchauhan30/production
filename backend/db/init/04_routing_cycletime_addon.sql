-- ============================================================
-- Chanda PPC — v2.3 Addon: Standard Cycle Time on Part Routing
--
-- WHY: standard_cycle_time_sec was only ever typed free-hand into each
-- daily production_oee_entries row -- there was no single master value
-- an operator's entry could be checked against. This adds the standard
-- (department-sheet) cycle time to part_routing, per (part_number,
-- operation_seq), so it becomes the one source of truth.
--
-- Safe to run on top of an already-running chanda_ppe database --
-- purely additive, one column, nullable (existing rows unaffected).
--
-- Apply with:
--   psql -h localhost -U ppe_user -d chanda_ppe -f ppe_schema_addon_v2.3_routing_cycletime.sql
-- or, if using Docker:
--   docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe < ppe_schema_addon_v2.3_routing_cycletime.sql
-- ============================================================

ALTER TABLE part_routing
    ADD COLUMN IF NOT EXISTS cycle_time_sec NUMERIC(10,2);

COMMENT ON COLUMN part_routing.cycle_time_sec IS
    'Standard cycle time in seconds, from the department cycle-time sheet. '
    'This is the reference value; production_oee_entries.standard_cycle_time_sec '
    'remains a per-entry field but should match this for the same part+operation.';

-- ============================================================
-- END OF ADDON v2.3
-- ============================================================
