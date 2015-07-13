# API for India Lights 

[![Build Status](https://magnum.travis-ci.com/developmentseed/india-lights-api.svg?token=D2qKHqm5aKKYaUVqKJaY&branch=develop)](https://magnum.travis-ci.com/developmentseed/india-lights-api)

The India Lights API shows light output at night for 20 years, from 1993 to 2013, for 600,000 villages across India. The Defense Meteorological Satellite Program (DMSP), run by the U.S. Department of Defense, has taken pictures of the Earth every night for 20 years. Researchers at the University of Michigan used the DMSP images to extract the data and provide it in tabular form. The India Lights API provides the data at convenient endpoints that allows you to look at specific time intervals and administration levels.

Browse the data at [nightlights.io](http://nightlights.io) or try the API at [http://api.nightlights.io](http://api.nightlights.io). You can also run your own instance!

**\>>>> [Documentation]( http://api.nightlights.io) <<<<**

## Generating the monthly summary data

The original data set comes in the form of nightly images from the DMSP satellites, available as TIF files from NOAA. This API is powered by monthly summaries of the light output of 600,000 villages, extracted from those TIFs.  The pipeline for generating the summaries is documented [here](summaries/README.md).


## Initializing the database

The API requires a connection to an instance of the `india-lights` database. You can create the database locally by following the installation documented [here](dbscripts/README.md).

## Installing the API locally

The API requires nodejs v0.12.0+ 

```
npm install

mv local.example.js local.js # <- fill in the db connection string
npm run develop
```
