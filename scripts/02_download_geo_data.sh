#!/usr/bin/env bash

current_dir=$(pwd)
mkdir -p ../input/settlements
cd ../input/settlements || exit 1

if [ ! -f raw/settlements.xls ]; then
  echo "settlements file missing. Downloading it from www.ksh.hu"
  settlements_url=http://www.ksh.hu/docs/helysegnevtar/hnt_letoltes_2019.xls
  wget $settlements_url -O raw/settlements.xls
fi

cp raw/settlements.xls ./

in2csv --write-sheets - settlements.xls > /dev/null
in2csv --names settlements.xls  > tabs.txt

cnt=0
while IFS= read -r line; do
  name=${line// /_}
  name=$(echo "$name" | iconv -f UTF-8 -t ascii//TRANSLIT//IGNORE | sed 's/[^a-zA-Z 0-9_]//g')
  cp settlements_$cnt.csv "$name".csv
  cnt=$((cnt+1))
done < tabs.txt

# last row is 'total', header is split into 2 rows so delete first one
sed -n -e "2,$(($(wc -l < Helysegek_2019_01_01.csv) - 1))p" Helysegek_2019_01_01.csv > helysegek.csv

rm settlements* tabs.txt
cd "$current_dir" || exit 2
exit 0
