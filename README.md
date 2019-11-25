# hungarianAgricultureSubsidies
### Code to process Hungarian Agricultural Subsidies data

## Manual preparation
   - Copy the project to your machine
   - Download Q interpreter from [kx.com](https://kx.com/connect-with-us/download/)
   - Download yearly data from [Hungarian Treasury](https://www.mvh.allamkincstar.gov.hu/kozzeteteli-listak1)
   - Unzip the files and move them under a directory called ```input/csv```. File names should be ```YYYY.csv```
   - Data is in Latin-2 encoding so it has to be converted to UTF-8. Use ```scripts/change_encoding.sh``` for this
