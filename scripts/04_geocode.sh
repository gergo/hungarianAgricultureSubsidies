#!/usr/bin/env bash

API_KEY=$(cat ../local/MAPS_API_KEY.txt)
export MAPS_API_KEY=${API_KEY}

for file in "../geocode/agrar_raw_"*".csv"
do
  f="$(basename -- "${file}")"
  index=$(echo ${f} | sed -e s/[^0-9]//g)
  echo "Processing file #${index}: ${f}"
  ./geocode.py --input ../geocode/agrar_raw_"${index}".csv --output ../geocode/agrar_output_"${index}".csv
done
