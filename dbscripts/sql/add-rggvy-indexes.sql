-- Drop everything
DROP INDEX IF EXISTS rgvy_energ_idx CASCADE;

-- Create indexes on tables
-- Do this after imports

CREATE INDEX rgvy_energ_idx ON rgvy (energ_date);
