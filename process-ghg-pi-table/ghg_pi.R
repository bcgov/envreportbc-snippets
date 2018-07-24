# Copyright 2018 Province of British Columbia
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

library(readxl)


## Import the .xlsx table from data/
dir <- "process-ghg-pi-table/data"
filename <- "2015_provinicial_inventory.xlsx"

## First get the data, without the headers (2 rows)
all_data <- read_xlsx(file.path(dir, filename), col_names = FALSE, skip = 2)

## First row (header) contains the main questions. Use ncol of all_data to get
## the cell range
colnames_1 <- read_xlsx(file.path(dir, filename), col_names = FALSE,
                        range = cell_limits(c(1,1), c(1, ncol(all_data)))) %>%
  unlist()

## Save the re-formatted data as CSV file
write_csv(data, (file.path(dir, paste0(data_year, "_bc_ghg_emissions.csv"))))
write_csv(metadata, (file.path(dir, paste0(data_year, "bc_ghg_emissions_metadata.csv"))))


