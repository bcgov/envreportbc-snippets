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



## Data Source

The `carip.R` script for formatting the CARIP survey output data expects one file to be in this `data/` directory&mdash;you will need to place the file here manually:

- e.g. `2017 CARIP raw data file.xlsx`

This file will (likely) have a year starting the filename. Edit the `carip.R` script&mdash;`line 5`&mdash;to set the `data_year`. Alternatively, you can edit the `carip.R` script&mdash;`line 9`&mdash;to import a file with a different file name.


