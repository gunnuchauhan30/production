-- ============================================================
-- Chanda PPC -- Add 'Tool Setting' to Down Time Reasons
--
-- Safe to re-run.
-- Apply with (PowerShell):
--   Get-Content add_tool_setting_reason.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

INSERT INTO down_time_reasons (reason) VALUES ('Tool Setting')
ON CONFLICT (reason) DO NOTHING;

SELECT reason FROM down_time_reasons ORDER BY id;

-- ============================================================
-- END
-- ============================================================
