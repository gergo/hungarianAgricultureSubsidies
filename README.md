# hungarianAgricultureSubsidies
### Code to process Hungarian Agricultural Subsidies data

## Prerequisites
Shell scripts do the work. You need a unix command line so either a Linux or Mac machine.
   - clone the project to your machine
   - Download Q interpreter from [kx.com](https://kx.com/connect-with-us/download/)
   - [R runtime](https://www.r-project.org/) if you want to run the analysis scripts
   - Python 3 and a Google Maps API-enabled api key to do address transformations

## Scripts
   - ```01_prepare_agricultural_subsidies_data.sh```
      - Download yearly data from [Hungarian Treasury](https://www.mvh.allamkincstar.gov.hu/kozzeteteli-listak1),
      - unzip the files and move them under a directory called ```input/csv```. File names should be
    ```YYYY.csv```
      - Data is in Latin-2 encoding so convert it to UTF-8
   - ```02_download_geo_data_sh```
      - Download settlement-level data from the Hungarian Statistics Agency [KSH](http://www.ksh.hu/docs/helysegnevtar/hnt_letoltes_2019.xls)
      - Extract sheets from the excel
   - ```03_postal_zips.sh```
      - Unfortunately, the zip info in the KSH file is incomplete so another [file](https://www.posta.hu/static/internet/download/Iranyitoszam-Internet_uj.xlsx) from the Postal Service is needed to join all addresses to the official settlement hierarchy
   - ```04_download_given_names.sh```
      - To determine genders of individual beneficiaries a list of the officially approved given names needs to be downloaded
   - ```05_geocode_pre.sh```
      - the shell script just calls a Q script that will load the full agricultural subsidies datased into memory
      - extract the unique zip+city+address triplets
      - and save them to csvs, each containing 2500 entries
   - ```06_geocode.sh```
      - run ```geocode.py``` python script on all of the csvs that were created in the previous step
      - call Google Maps API to geocode the addresses -> get latitude/longitude and a standardized, clean address set
      - TODO: load all of the geocoded addresses into memory and check which ones failed. If not too many then fix manually.
   - ```07_export_to_csvs.sh```
      - load all datasets into memory
      - merge them
      - save them to normalized csvs so it's easier to re-use in other projects

## Analysis
   - ```10_create_network.sh```: Raw data is processed to create cleaner, aggregate datasets.
   - ```11_analysis.sh```: Starts a q server to save data about some interesting findings and to do ad-hoc analysis.
   - ```NetworkAnalysis.ipynb```: Interactive python notebook to analyze the networks created by the above scripts.
   - [agrar_analysis.Rmd](r/agrar_analysis.Rmd) can be used to generate visualizations and models. The output is also available [in the repo](r/agrar_analysis.pdf)

## Improvement Ideas
  - join agricultural subsidies with election data to see what influence municipal leadership has on wins
  - add an interactive gui: ideally a javascript-based pivot table or map-based tool would enable users to find patterns
