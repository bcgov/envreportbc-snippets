```{=html}
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
```
[![img](https://img.shields.io/badge/Lifecycle-Stable-97ca00)](https://github.com/bcgov/repomountie/blob/master/doc/lifecycle-badges.md)

## Convert Provincial GHG Inventory Table to Machine-Readable CSV Format

This script supports the re-formatting of the anually released [British Columbia Provincial Greenhouse Gas Inventory Table](https://www2.gov.bc.ca/gov/content?id=50B908BE85E0446EB6D3C434B4C8C106).

### Usage

Process annual [Provincial GHG Inventory Table](https://www2.gov.bc.ca/gov/content?id=50B908BE85E0446EB6D3C434B4C8C106) .xlsx file:

-   download the updated Provincial Inventory .xlsx file and place it in the process-ghg-pi-table/data folder
-   the ghg_pi_ipcc-sector.R script writes out a re-formatted .csv file of the GHGs by IPCC sector
-   the ghg_pi_econ-sector.R script writes out a re-formatted .csv file by ECCC economic sector

### More Information

You can learn about the Provincial Greenhouse Gas Inventory [here](https://www2.gov.bc.ca/gov/content?id=50B908BE85E0446EB6D3C434B4C8C106).
