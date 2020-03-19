#!/usr/bin/env bash

current_dir=$(pwd)
mkdir ../input/settlements
cd ../input/settlements || exit 1

settlements_url=http://www.ksh.hu/docs/helysegnevtar/hnt_letoltes_2019.xls
wget $settlements_url -O settlements.xls

in2csv --write-sheets - settlements.xls > /dev/null
in2csv --names settlements.xls  > tabs.txt

cnt=0
while IFS= read -r line; do
  name=${line// /_}
  name=$(echo "$name" | iconv -f UTF-8 -t ascii//TRANSLIT//IGNORE | sed 's/[^a-zA-Z 0-9_]//g')
  cp settlements_$cnt.csv "$name".csv
  cnt=$((cnt+1))
done < tabs.txt


cd $current_dir || exit 2
exit 0
