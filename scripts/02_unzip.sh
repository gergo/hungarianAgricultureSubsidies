#!/usr/bin/env bash

mkdir ../input/csv

for file in "../input/zip/"*
do
  f="$(basename -- ${file})"
  filename="${f%.*}"
  echo "Processing ${f}"
  unzip ${file} -d ../input/csv/
  mv ../input/csv/export.csv ../input/csv/${filename}.csv
done
