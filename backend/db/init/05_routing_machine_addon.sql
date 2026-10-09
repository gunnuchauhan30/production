-- ============================================================
-- Chanda PPC — v2.4 Addon: Machine Code on Part Routing
--
-- The notebook cycle-time sheets record a machine code (e.g. KM-01,
-- BM-02, DM-01,02,03) alongside every operation's standard cycle
-- time. This adds that as a free-text reference field on
-- part_routing -- free-text because a single operation is sometimes
-- run on any of several interchangeable machines (e.g. "DM-01,02,03").
--
-- Apply with (PowerShell):
--   Get-Content ppe_schema_addon_v2.4_routing_machine.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

ALTER TABLE part_routing
    ADD COLUMN IF NOT EXISTS machine_no VARCHAR(80);

COMMENT ON COLUMN part_routing.machine_no IS
    'Machine code(s) this operation normally runs on, from the cycle-time sheet '
    '(free text -- may list more than one interchangeable machine, e.g. "DM-01,02,03").';

-- ============================================================
-- END OF ADDON v2.4
-- ============================================================
