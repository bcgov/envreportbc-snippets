## Data Source

The script for adding the annual snapshot of BCSEE data to the [historical data object available in the B.C. Data Catalogue](https://catalogue.data.gov.bc.ca/dataset/d3651b8c-f560-48f7-a34e-26b0afc77d84) expects two files to be in this `data/` directory&mdash;you will need to place them here manually:

- `RecentYear_Plants_Animals.xlsx`
- `RecentYear_Communities.xlsx` 

These files will (likely) have a year starting each filename in the source directory, but should be copied into the `data/` folder with the above name. Alternatively, you can edit the `bcsee.R lines 56-57` to import files with different file names.

