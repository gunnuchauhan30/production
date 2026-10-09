-- ============================================================
-- Chanda PPC — v2.2 Reports Addon
-- Adds:
--   1. "line" column on production_oee_entries (Tube Line / Fabrication Line)
--      so OEE entries can be split into the two shop-floor lines.
--   2. press_stock_entries table — daily press-shop stroke count log
--      (operator, machine no., tonnage, strokes, strokes rate).
-- Runs automatically, once, the first time the DB container starts
-- with an empty database (see docker-compose.yml init order: 03).
-- ============================================================

-- 1. Line tag on OEE entries -----------------------------------
ALTER TABLE production_oee_entries
    ADD COLUMN IF NOT EXISTS line VARCHAR(30) NOT NULL DEFAULT 'Fabrication Line';

CREATE INDEX IF NOT EXISTS idx_oee_line ON production_oee_entries(line);

-- 2. Press Shop — daily strokes count ----------------------------
CREATE TABLE IF NOT EXISTS press_stock_entries (
    id              SERIAL PRIMARY KEY,
    entry_date      DATE NOT NULL,
    shift           VARCHAR(10),
    operator_name   VARCHAR(150),
    machine_no      VARCHAR(30),          -- e.g. PP-03, PP-07
    tonnage         NUMERIC(10,2),
    strokes         NUMERIC(12,2) NOT NULL DEFAULT 0,
    strokes_rate    NUMERIC(10,4),        -- Rs. or unit rate per stroke
    calculation     NUMERIC(12,2) GENERATED ALWAYS AS
                         (COALESCE(strokes,0) * COALESCE(strokes_rate,0)) STORED,
    remarks         VARCHAR(200),
    entry_by        INTEGER REFERENCES ppe_users(id),
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_press_stock_date ON press_stock_entries(entry_date);
CREATE INDEX IF NOT EXISTS idx_press_stock_machine ON press_stock_entries(machine_no);
