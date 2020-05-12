#!/usr/bin/env bash

# download raw, zipped data
mkdir -p ../input/zip

years=(2011 2012 2013 2014 2015 2016 2017 2018 2019)
ids=(  17   22   26   31   38   42   48   54   60)

for i in "${!years[@]}"; do
  wget https://www.mvh.allamkincstar.gov.hu/documents/20182/3575117/tamkereso_10000"${ids[$i]}" -O ../input/zip/"${years[$i]}".zip
done

# unzip files
mkdir -p ../input/csv

# 2010 data is part of the project as it is no longer available for download
unzip ../input/zip/old_2010.csv.zip -d ../input/csv/

for file in "../input/zip/"*
do
  f="$(basename -- "${file}")"
  filename="${f%.*}"
  echo "Processing ${f}"
  unzip "${file}" -d ../input/csv/
  mv ../input/csv/export.csv ../input/csv/"${filename}".csv
done

# change encodings
FROM_ENCODING="ISO-8859-2//IGNORE"
TO_ENCODING="UTF-8"

CONVERT=" iconv -f $FROM_ENCODING -t $TO_ENCODING"
cd "$(pwd)"/../input/csv/ || exit

for file in ????.csv; do
    echo converting "$file"
    $CONVERT "$file" > "utf8_${file}"
done
exit 0
