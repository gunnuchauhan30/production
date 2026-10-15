-- Roles: 'operator' is renamed to 'operation'; 'production' and 'accounts' are added.
-- (An existing database gets the same change automatically when the backend starts.)
ALTER TYPE ppe_role_enum RENAME VALUE 'operator' TO 'operation';
ALTER TYPE ppe_role_enum ADD VALUE IF NOT EXISTS 'production';
ALTER TYPE ppe_role_enum ADD VALUE IF NOT EXISTS 'accounts';
