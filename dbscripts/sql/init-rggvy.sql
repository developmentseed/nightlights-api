DROP TABLE IF EXISTS rgvy CASCADE;

-- RGGVY Program table
CREATE TABLE rgvy (
  villagecode bigint primary key REFERENCES villages (villagecode),
  energ_date timestamp
);
