-- ============================================================
-- Chanda PPC — v2.6 Addon: Parts (friendly display name)
--
-- Lets a part_number (e.g. "J1A") carry a human-readable name
-- (e.g. "Handle Bar") so the Master Data screen can show
-- "Handle Bar J1A" instead of just "J1A".
--
-- Apply with (PowerShell):
--   Get-Content ppe_schema_addon_v2.6_parts.sql | docker exec -i chanda_ppe_db psql -U ppe_user -d chanda_ppe
-- ============================================================

CREATE TABLE IF NOT EXISTS parts (
    part_number     VARCHAR(80) PRIMARY KEY,
    part_name       VARCHAR(150),                -- e.g. "Handle Bar"
    customer_name   VARCHAR(200)                 -- e.g. "UNO MINDA, VARROC"
);

-- Safe to re-run: adds the column if this table already existed without it
-- (e.g. it was created by an earlier version of this same addon file).
ALTER TABLE parts ADD COLUMN IF NOT EXISTS customer_name VARCHAR(200);

-- ============================================================
-- END OF ADDON v2.6
-- ============================================================
