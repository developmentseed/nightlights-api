awk 'BEGIN { printf "COPY '$2' FROM STDIN WITH (FORMAT CSV,HEADER '\''FALSE'\'', NULL '\'''\'');\n";} \
  {print;} END {print "\\.";}' | psql $1