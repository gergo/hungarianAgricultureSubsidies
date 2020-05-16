#!/usr/bin/env bash

# download raw, zipped data
mkdir -p ../input/zip

years=(2011 2012 2013 2014 2015 2016 2017 2018 2019)
ids=(  17   22   26   31   38   42   48   54   60)

for i in "${!years[@]}"; do
  if [ ! -f ../input/zip/"${years[$i]}".zip ]; then
    wget https://www.mvh.allamkincstar.gov.hu/documents/20182/3575117/tamkereso_10000"${ids[$i]}" -O ../input/zip/"${years[$i]}".zip
  else
    # shellcheck disable=SC2140
    echo "\""../input/zip/"${years[$i]}".zip"\" file is already present so not downloading it again"
  fi
done

# unzip files
mkdir -p ../input/csv

# 2010 data is part of the project as it is no longer available for download
if [ ! -f ../input/csv/old_2010.csv ]; then
  unzip ../input/zip/old_2010.csv.zip -d ../input/csv/
else
  echo ../input/csv/"2010.csv is already present so not overwriting it"
fi

for file in "../input/zip/"????.zip
do
  f="$(basename -- "${file}")"
  filename="${f%.*}"
  if [ ! -f ../input/csv/"${filename}".csv ]; then
    echo "Processing ${f}"
    unzip "${file}" -d ../input/csv/
    mv ../input/csv/export.csv ../input/csv/"${filename}".csv
  else
    # shellcheck disable=SC2140
    echo ../input/csv/"${filename}".csv" is already present so not overwriting it"
  fi
done

# change encodings
FROM_ENCODING="ISO-8859-2//IGNORE"
TO_ENCODING="UTF-8"

CONVERT=" iconv -f $FROM_ENCODING -t $TO_ENCODING"
cd "$(pwd)"/../input/csv/ || exit

for file in ????.csv; do
  target_filename=utf8_${file}
  if [ ! -f "$target_filename" ]; then
    echo converting "$file"
    $CONVERT "$file" > "utf8_${file}"
  else
    echo "$target_filename"" is already there so not re-encoding it"
  fi
done
exit 0
