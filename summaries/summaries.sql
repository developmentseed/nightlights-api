
---connect with:
---psql -h redshift-host-url.com -U username -d dbname -p port

--- Amazon credentials should be in the form:
--- 'aws_access_key_id=ACCESS_KEY;aws_secret_access_key=SECRET_KEY'

-- at any point, to get error details:
-- select query, substring(filename,22,25) as filename,line_number as line, substring(colname,0,12) as column, type, position as pos, substring(raw_line,0,30) as line_text, substring(raw_field_value,0,15) as field_text, substring(err_reason,0,45) as reason from stl_load_errors order by query desc limit 10;


--- DATA IMPORT ---

drop table villages;
copy villages from 's3://your-bucket/india-lights-summary/villages.csv' credentials
CREDENTIALS
csv null as 'NA' ignoreheader 1;

drop table nights;
copy nights from 's3://your-bucket/india-lights-cleaned/nightlights' credentials
CREDENTIALS
gzip csv null as '';

CREATE TABLE villages_new (
  villagecode bigint primary key,
  longitude real,
  latitude real,
  state character varying(17),
  district character varying(27),
  acid smallint
)
distkey(villagecode)
sortkey(villagecode);

update villages set villagecode=-1 where villagecode is null;
update nights set villagecode=-1 where villagecode is null;
insert into villages_new select * from villages;
drop table villages;
alter table villages_new rename to villages;

create table nights_new
  distkey(villagecode)
  sortkey(villagecode,year,month,day)
as select
  villagecode,
  cast(substring(satellite, 1, 3) as varchar(3)) as satellite,
  cast(substring(satellite, 4) as smallint) as year,
  month, day, "timestamp", cm, li, tir, vis, sam, slm
from nights;
drop table nights;
alter table nights_new rename to nights;
alter table nights add foreign key (villagecode) references villages;

--- AGGREGATIONS ---

--- By State ---

drop table states;
create table states
  distkey(state)
  sortkey(state, year, month, day)
as select
  state, year, month, day, satellite,
  count(*) as count,
  cast(avg(vis::dec(6,4)) as dec(6,4)) as vis_mean,
  cast(stddev_samp(vis) as dec(6,4)) as vis_sd,
  min(vis) as vis_min,
  min(median) as vis_median,
  max(vis) as vis_max

from (
  select nights.villagecode, nights.year, nights.month, nights.day,
  nights.satellite, nights.vis, villages.state, villages.district,
  median(nights.vis) over (partition by state, year, month, day, satellite) as median
  from nights, villages
  where nights.villagecode=villages.villagecode
    and cm <> 1 and slm=0 and sam not between 302 and 304 and sam not between 1162 and 1164
)
group by state, year, month, day, satellite;

drop table states_distribution;
create table states_distribution
  distkey(state)
  sortkey(state, year, month, day)
as select 
  state, year, month, day, satellite,
  quintile, 
  min(vis) as min,
  max(vis) as max
from (
  select 
    state, year, month, day, satellite,
    vis, 
    ntile(5) over (partition by state, year, month, day, satellite order by vis asc) quintile
  from (
    select nights.villagecode, nights.year, nights.month, nights.day,
    nights.satellite, nights.vis, villages.state, villages.district
    from nights, villages
    where nights.villagecode=villages.villagecode
      and cm <> 1 and slm=0 and sam not between 302 and 304 and sam not between 1162 and 1164
  )
)
group by state, year, month, day, satellite, quintile;


--- States aggregated to months ---

drop table states_months;
create table states_months
  distkey(state)
  sortkey(state, year, month)
as select
  state, year, month, satellite,
  count(*) as count,
  cast(avg(vis::dec(6,4)) as dec(6,4)) as vis_mean,
  cast(stddev_samp(vis) as dec(6,4)) as vis_sd,
  min(vis) as vis_min,
  min(median) as vis_median,
  max(vis) as vis_max

from (
  select nights.villagecode, nights.year, nights.month,
  nights.satellite, nights.vis, villages.state, villages.district,
  median(nights.vis) over (partition by state, year, month, satellite) as median
  from nights, villages
  where nights.villagecode=villages.villagecode
    and cm <> 1 and slm=0 and sam not between 302 and 304 and sam not between 1162 and 1164
)
group by state, year, month, satellite;

drop table states_months_distribution;
create table states_months_distribution
  distkey(state)
  sortkey(state, year, month)
as select 
  state, year, month, satellite,
  quintile, 
  min(vis) as min,
  max(vis) as max
from (
  select 
    state, year, month, satellite,
    vis, 
    ntile(5) over (partition by state, year, month, satellite order by vis asc) quintile
  from (
    select nights.villagecode, nights.year, nights.month,
    nights.satellite, nights.vis, villages.state, villages.district
    from nights, villages
    where nights.villagecode=villages.villagecode
      and cm <> 1 and slm=0 and sam not between 302 and 304 and sam not between 1162 and 1164
  )
)
group by state, year, month, satellite, quintile;


--- By District ---


drop table districts;
create table districts
  distkey(district)
  sortkey(state, district, year, month)
as select
  state, district, year, month, satellite,
  count(*) as count,
  cast(avg(cast(vis as dec(6,4))) as dec(6,4)) as vis_mean,
  cast(stddev_samp(vis) as dec(6,4)) as vis_sd,
  min(vis) as vis_min,
  min(median) as vis_median,
  max(vis) as vis_max
from (
  select nights.villagecode, nights.year, nights.month, nights.day,
    nights.satellite, nights.vis, villages.state, villages.district,
    median(nights.vis) over (partition by state, district, year, month, satellite) as median

  from nights, villages
  where nights.villagecode=villages.villagecode
    and cm <> 1 and slm=0 and sam not between 302 and 304 and sam not between 1162 and 1164
)
group by state, district, year, month, satellite;


drop table districts_distribution;
create table districts_distribution
  distkey(district)
  sortkey(state, district, year, month)
as select 
  state, district, year, month, satellite,
  quintile, 
  min(vis) as min,
  max(vis) as max
from (
  select 
    state, district, year, month, satellite,
    vis, 
    ntile(5) over (partition by state, district, year, month, satellite order by vis asc) quintile
  from (
    select nights.villagecode, nights.year, nights.month,
    nights.satellite, nights.vis, villages.state, villages.district
    from nights, villages
    where nights.villagecode=villages.villagecode
      and cm <> 1 and slm=0 and sam not between 302 and 304 and sam not between 1162 and 1164
  )
)
group by state, district, year, month, satellite, quintile;


drop table districts_daily;
create table districts_daily
  distkey(district)
  sortkey(state, district, year, month, day)
as select
  state, district, year, month, day, satellite,
  count(*) as count,
  cast(avg(cast(vis as dec(6,4))) as dec(6,4)) as vis_mean,
  cast(stddev_samp(vis) as dec(6,4)) as vis_sd,
  min(vis) as vis_min,
  min(median) as vis_median,
  max(vis) as vis_max
from (
  select nights.villagecode, nights.year, nights.month, nights.day,
    nights.satellite, nights.vis, villages.state, villages.district,
    median(nights.vis) over (partition by state, district, year, month, day, satellite) as median
  from nights, villages
  where nights.villagecode=villages.villagecode
    and cm <> 1 and slm=0 and sam not between 302 and 304 and sam not between 1162 and 1164
)
group by state, district, year, month, day, satellite;


drop table years;
create table years
  distkey(villagecode)
  sortkey(villagecode,year)
as select
  villagecode, year, satellite,
  count(*) as nights_count,
  cast(avg(cast(vis as dec(6,4))) as dec(6,4)) as vis_mean,
  cast(stddev_samp(vis) as dec(6,4)) as vis_sd,
  min(vis) as vis_min,
  min(median) as vis_median,
  max(vis) as vis_max
from (select *,
  median(vis) over (partition by villagecode, year, satellite) as median
  from nights
  where cm <> 1 and slm=0 and sam not between 302 and 304 and sam not between 1162 and 1164
)
group by villagecode, year, satellite ;


drop table years_distribution;
create table years_distribution
  distkey(villagecode)
  sortkey(villagecode,year)
as select 
  villagecode, year, satellite,
  quintile, 
  min(vis) as min,
  max(vis) as max
from (
  select 
    villagecode, year, satellite,
    vis, 
    ntile(5) over (partition by villagecode, year, satellite order by vis asc) quintile
  from (
    select villagecode, year, satellite, vis from nights
  where cm <> 1 and slm=0 and sam not between 302 and 304 and sam not between 1162 and 1164
  )
)
group by villagecode, year, satellite, quintile;


drop table months;
create table months
  distkey(villagecode)
  sortkey(villagecode, year, month)
as select
  villagecode, year, month, satellite,
  count(*) as nights_count,
  cast(avg(cast(vis as dec(6,4))) as dec(6,4)) as vis_mean,
  cast(stddev_samp(vis) as dec(6,4)) as vis_sd,
  min(vis) as vis_min,
  min(median) as vis_median,
  max(vis) as vis_max
from (select *,
  median(vis) over (partition by villagecode, year, month, satellite) as median
  from nights
  where cm <> 1 and slm=0 and sam not between 302 and 304 and sam not between 1162 and 1164
)
group by villagecode, year, month, satellite;

drop table months_distribution;
create table months_distribution
  distkey(villagecode)
  sortkey(villagecode,year, month)
as select 
  villagecode, year, month, satellite,
  quintile, 
  min(vis) as min,
  max(vis) as max
from (
  select 
    villagecode, year, month, satellite,
    vis, 
    ntile(5) over (partition by villagecode, year, month, satellite order by vis asc) quintile
  from (
    select villagecode, year, month, satellite, vis from nights
  where cm <> 1 and slm=0 and sam not between 302 and 304 and sam not between 1162 and 1164
  )
)
group by villagecode, year, month, satellite, quintile;



--- NIGHTLY STATS ACROSS ALL VILLAGES ---

drop table nightly_stats;
create table nightly_stats
as select
  year, month, day, satellite,
  count(*) as count,
  min(vis) as vis_min,
  min(vis_median) as vis_median,
  max(vis) as vis_max,
  avg(cast(vis as dec(6,4))) as vis_mean,
  variance(vis) as vis_var,
  min(li_median) as li_median,
  avg(li) as li_mean
from (select *,
  median(vis) over (partition by year, month, day, satellite) as vis_median,
  median(li) over (partition by year, month, day, satellite) as li_median  
  from nights
  where cm <> 1 and slm=0 and sam not between 302 and 304 and sam not between 1162 and 1164
)
group by year, month, day, satellite;

create table nightly_total_count
as select year, month, day, satellite, count(*) as count
from nights group by year, month, day, satellite;

create table nightly_stats_new
as select
  filtered.year, filtered.month, filtered.day, filtered.satellite,
  filtered.count as filtered_count,
  rawdata.count as raw_count,
  filtered.vis_mean,
  filtered.vis_min,
  filtered.vis_median,
  filtered.vis_max,
  filtered.vis_var,
  filtered.li_median,
  filtered.li_mean
from nightly_stats as filtered, nightly_total_count as rawdata
where (rawdata.year = filtered.year) and
  (rawdata.month = filtered.month) and
  (rawdata.day = filtered.day) and
  (rawdata.satellite = filtered.satellite);

drop table nightly_stats;
drop table nightly_total_count;
alter table nightly_stats_new rename to nightly_stats;


drop table nightly_stats_distribution;
create table nightly_stats_distribution
  sortkey(year, month, day, satellite)
as select
  year, month, day, satellite,
  quintile, 
  min(vis) as min,
  max(vis) as max
from (
  select 
    year, month, day, satellite,
    vis, 
    ntile(5) over (partition by year, month, day, satellite order by vis asc) quintile
  from (
    select year, month, day, satellite, vis from nights
  where cm <> 1 and slm=0 and sam not between 302 and 304 and sam not between 1162 and 1164
  )
)
group by year, month, day, satellite, quintile;


unload ('select * from nights where villagecode in ( with ranked as (select state, district, villagecode, row_number() over(partition by state order by random()) as rn from villages) select villagecode from ranked where rn <= 25) order by villagecode, year, month, day')
to  's3://your-bucket/india-lights-summary/nightly-sample/nightly-sample.csv'
credentials CREDENTIALS
gzip delimiter ',';


unload ('select * from nightly_stats order by year, month, day')
to 's3://your-bucket/india-lights-summary/nightly-stats/nightly-stats.csv'
credentials CREDENTIALS
gzip delimiter ',';

unload ('select * from states order by state, year, month, day')
to 's3://your-bucket/india-lights-summary/states/states.csv'
credentials CREDENTIALS
gzip delimiter ',';

unload ('select * from districts order by district, year, month')
to 's3://your-bucket/india-lights-summary/districts/districts.csv'
credentials CREDENTIALS
gzip delimiter ',';

unload ('select * from districts_daily order by district, year, month, day')
to 's3://your-bucket/india-lights-summary/districts-daily/districts-daily.csv'
credentials CREDENTIALS
gzip delimiter ',';

unload ('select * from years order by villagecode, year')
to 's3://your-bucket/india-lights-summary/years/years.csv'
credentials CREDENTIALS
gzip delimiter ',';

unload ('select * from months order by villagecode, year, month')
to 's3://your-bucket/india-lights-summary/months/months.csv'
credentials CREDENTIALS
gzip delimiter ',';

unload('select * from states_months order by state, year, month')
to 's3://your-bucket/india-lights-summary/states-months/states-months.csv'
credentials CREDENTIALS
gzip delimiter ',';

unload('select * from states_months_distribution order by state, year, month')
to 's3://your-bucket/india-lights-summary/states-months-distribution/states-months-distribution.csv'
credentials CREDENTIALS
gzip delimiter ',';

unload('select * from states_distribution order by state, year, month, day')
to 's3://your-bucket/india-lights-summary/states-distribution/states-distribution.csv'
credentials CREDENTIALS
gzip delimiter ',';

unload('select * from districts_distribution order by state, district, year, month')
to 's3://your-bucket/india-lights-summary/districts-distribution/districts-distribution.csv'
credentials CREDENTIALS
gzip delimiter ',';

unload('select * from months_distribution order by villagecode, year, month')
to 's3://your-bucket/india-lights-summary/months-distribution/months-distribution.csv'
credentials CREDENTIALS
gzip delimiter ',';

unload('select * from years_distribution order by villagecode, year')
to 's3://your-bucket/india-lights-summary/years-distribution/years-distribution.csv'
credentials CREDENTIALS
gzip delimiter ',';

unload('select * from nightly_stats_distribution order by year, month, day, satellite')
to 's3://your-bucket/india-lights-summary/nightly-stats-distribution/nightly-stats-distribution.csv'
credentials CREDENTIALS
gzip delimiter ',';
