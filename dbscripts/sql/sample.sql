COPY (select
villages_month.villagecode,
villages_month.year,
villages_month.month,
villages_month.vis_median,
villages.lon, villages.lat,
villages.dkey,
villages.skey
from villages_month join (
  select 
  villages.villagecode, 
  villages.longitude as lon, villages.latitude as lat, 
  villages.district_key as dkey, 
  districts.state_key as skey,
  percent_rank() OVER (partition by districts.district_key ORDER by random()) as row
  from villages join districts on villages.district_key=districts.district_key 
) as villages 
on villages_month.villagecode=villages.villagecode
where villages.row <= 0.1) TO STDOUT WITH CSV HEADER