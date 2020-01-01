#!/usr/bin/env bash

mkdir ../input/zip

years=(2014 2015 2016 2017 2018 2019)
ids=(1000031 1000038 1000042 1000048 1000054 1000059)

for i in ${!years[@]}; do
  wget https://www.mvh.allamkincstar.gov.hu/documents/20182/3575117/tamkereso_${ids[$i]} -O ../input/zip/${years[$i]}.zip
done
