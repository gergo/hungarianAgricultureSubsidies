# hungarianAgricultureSubsidies
### Code to process Hungarian Agricultural Subsidies data

## Manual preparation
Shell scripts do the work.
   - Copy the project to your machine
   - Download Q interpreter from [kx.com](https://kx.com/connect-with-us/download/)
   - ```01_prepare_agricultural_subsidies_data.sh```
      - Download yearly data from [Hungarian Treasury](https://www.mvh.allamkincstar.gov.hu/kozzeteteli-listak1),
      - unzip the files and move them under a directory called ```input/csv```. File names should be
    ```YYYY.csv```
      - Data is in Latin-2 encoding so it has to be converted to UTF-8.

## Analysis
   - ```04_create_network.sh```: Raw data is processed to create cleaner, aggregate datasets.
   - ```05_analysis.sh```: Starts a q server to save data about some interesting findings and to do ad-hoc analysis.
   - ```NetworkAnalysis.ipynb```: Interactive python notebook to analyze the networks created by the above scripts.

## Improvement Ideas
  - join agricultural subsidies with election data to see what influence municipal leadership has on wins
  - refine ZIP code matching: big cities have multiple zip codes
  - join data with population density to see how much money is won per resident in each city
  - add some interactive gui: ideally a javascript-based pivot table would enable users to find patterns