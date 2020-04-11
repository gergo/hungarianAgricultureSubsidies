#!/usr/bin/env bash

API_KEY=$(cat ../local/MAPS_API_KEY.txt)
export MAPS_API_KEY=${API_KEY}

read -p "Test or full run? [test,full]: " run_mode

function test_run() {
  echo 'test_run'
  ./geocode.py --input ../geocode/agrar_test.csv --output ../geocode/agrar_output_test.csv
}

function full_run() {
  echo 'full run! Might take long and you might be charged for using the google maps api'
  for file in "../geocode/agrar_raw_"*".csv"
  do
    f="$(basename -- "${file}")"
    index=$(echo ${f} | sed -e s/[^0-9]//g)
    echo "Processing file #${index}: ${f}"
    ./geocode.py --input ../geocode/agrar_raw_"${index}".csv --output ../geocode/agrar_output_"${index}".csv
  done
}

case $run_mode in
  test|TEST) test_run ;;
  full|FULL) full_run ;;
  *) echo 'Choose "test" or "full" run mode' ;;
esac
