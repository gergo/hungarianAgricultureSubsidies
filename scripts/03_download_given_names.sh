#!/usr/bin/env bash

current_dir=$(pwd)
mkdir -p ../input/names
cd ../input/names || exit 1

names_root="http://www.nytud.mta.hu/oszt/nyelvmuvelo/utonevek/"

function download_names() {
  group_name=$1
  echo "checking $group_name"
  if [ ! -f "$group_name".txt ]; then
    echo "$group_name file missing. Downloading it from www.nytud.mta.hu"
    settlements_url=${names_root}/$group_name
    curl -f "$settlements_url" | iconv -f "ISO-8859-2//IGNORE" -t "UTF-8" | sed -e 's/.* -- //g' > "$group_name".txt
  fi
}

download_names "osszesnoi"
download_names "osszesffi"

cd "$current_dir" || exit 2
exit 0
