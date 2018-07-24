<!--
Copyright 2018 Province of British Columbia

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations under the License.
-->

## Data Sources

The `bcsee.r` script for adding the annual output of BCSEE data to the [historical data object available in the B.C. Data Catalogue](https://catalogue.data.gov.bc.ca/dataset/d3651b8c-f560-48f7-a34e-26b0afc77d84) expects two files to be in this `data/` directory&mdash;you will need to place them here manually:

- `RecentYear_Plants_Animals.xlsx`
- `RecentYear_Communities.xlsx` 

These files will (likely) have a year starting each filename in the source directory, but should be copied into the `data/` folder with the above name. Alternatively, you can edit the `bcsee.R` script&mdash;`lines 56-57`&mdash;to import files with different file names.

