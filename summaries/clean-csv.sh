#!/usr/bin/env bash

# Use this script with GNU parallel:
# parallel ./clean-csv.sh ::: beep/boop/*.csv

# Make a temp file
tempfoo=`basename $1`
TMPFILE=`mktemp /tmp/${tempfoo}.XXXXXX` || exit 1

# Exit script if the processing fails
set -e

# First remove header rows (of which there are many)
# Then replace NA with empty string
# Then remove redundant village metadata
cat $1 \
  | sed -e '/^"state"/ d' \
  | sed -e 's/NA//g' \
  | csvcut -C 1,2,3,4,6,7 \
  > $TMPFILE

echo "Done processing $1"
# Replace original with processed
mv $TMPFILE $1
