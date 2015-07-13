--- Generate district key
ALTER TABLE districts_boundaries ADD COLUMN district_key varchar(50);
UPDATE districts_boundaries SET
  district_key = lower(replace(state_ut,' ','-')) || '-' || lower(replace(district,' ', '-'));

--- Dissolve duplicate districts
--- NOTE: we average the population data because it's duplicated in the shpaefile.
drop table if exists districts_boundaries_merged;
create table districts_boundaries_merged as
select
  district_key,
  lower(replace(state_ut, ' ', '-')) as state_key,
  avg(tot_pop) as tot_pop,
  avg(f_pop) as f_pop,
  avg(tot_lit) as tot_lit,
  ST_Union(geom) as geom
from districts_boundaries
group by state_key, district_key;

drop table districts_boundaries;
alter table districts_boundaries_merged rename to districts_boundaries;

--- Dissolve districts into states
drop table if exists states_boundaries;
create table states_boundaries as
select
  state_key,
  sum(tot_pop) as tot_pop,
  sum(f_pop) as f_pop,
  sum(tot_lit) as tot_lit,
  ST_Union(geom) as geom
from districts_boundaries
group by state_key;
