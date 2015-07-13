# Summary Data

## Dependencies

The following pipeline depends on:

 - R >= v3.0
 - csvcut

## Extract tabular data from nightly TIFs

Use [this R script](DMSP_extract.R) to extract data for village points like so:

```sh
r --slave --no-restore --file=DMSP_extract.R --args /absolute/path/to/village-points.shp input-dir output-dir
```

Note that for the entire 20-year timespan, the final output is ~1.2 TB, so that doing the entire extraction in serial is infeasible.


## Clean the CSV

[clean-csv.sh](clean-csv.sh) does a bit of cleanup on the CSV, preparing it for
use with Redshift (or another SQL) db.  Use it with `./clean-csv.sh
the-csv-file.csv`, or parallelize with GNU parallel with `parallel
./clean-csv.sh ::: your/csv/files/*.csv`.

## Generate summaries

For generating the monthly summaries of the dataset, we used Amazon Redshift to
deal with the large volume of data, but the scripts could be relatively easily
adapted to another SQL database.

To use redshift to create summaries, put the cleaned CSV data onto an S3
bucket, and then use [summaries.sql](summaries.sql) to generate the summaries,
replacing `credentials` in `summaries.sql` with your AWS credentials.

