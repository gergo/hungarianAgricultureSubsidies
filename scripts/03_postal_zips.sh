#!/usr/bin/env bash

current_dir=$(pwd)
mkdir -p ../input/zip_map
cd ../input/zip_map || exit 1

if [ ! -f post_codes.xlsx ]; then
  echo "post_codes file missing. Downloading it from www.posta.hu"
  post_codes_url=https://www.posta.hu/static/internet/download/Iranyitoszam-Internet_uj.xlsx
  wget $post_codes_url -O post_codes.xlsx
fi

in2csv --write-sheets - post_codes.xlsx > /dev/null
in2csv --names post_codes.xlsx  > tabs.txt

cnt=0
while IFS= read -r line; do
  name=${line// /_}
  name=$(echo "$name" | iconv -f UTF-8 -t ascii//TRANSLIT//IGNORE | sed 's/[^a-zA-Z 0-9_]//g')
  cp post_codes_$cnt.csv "$name".csv
  cnt=$((cnt+1))
done < tabs.txt

sed -n -e "2,$(($(wc -l < Telepulesek.csv)))p" Telepulesek.csv > zip_map.csv

rm post_codes_* tabs.txt
cd "$current_dir" || exit 2
exit 0
