#!/bin/bash
P="psql -h /tmp/pg -X -q"
$P -d cinema -v ON_ERROR_STOP=1 -f schema.sql >/dev/null 2>&1
$P -d cinema -v ON_ERROR_STOP=1 -f seed.sql >/dev/null 2>&1
$P -d cinema -f queries.sql > out_queries.txt 2>&1
python3 idx.py > out_idx.txt 2>&1
$P -d cinema -f tests.sql > out_tests.txt 2>&1
