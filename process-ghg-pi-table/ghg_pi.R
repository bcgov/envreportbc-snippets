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
library(dplyr)
library(readr)


## Import the .xlsx table from data/
dir <- "process-ghg-pi-table/data"
filename <- "2015_provincial_inventory.xlsx"


## Get the metadata
units <- read_xlsx(file.path(dir, filename),
                   col_names = c("Note", "blank1", "blank2", "Comment"),
                   range = cell_rows(6)) %>%
  select(Note, Comment)

metadata <- read_xlsx(file.path(dir, filename),
                      col_names = c("Note","Comment"),
                      range = cell_rows(86:92)) %>%
  rbind(units)


## Get the column names
newcols <- colnames(read_xlsx(file.path(dir, filename),
                              col_names = TRUE, skip = 1))

## Get the core data, without the title, empty leading rows & metadata, & add new column names
data <- read_xlsx(file.path(dir, filename),
                  col_names = newcols,
                  skip = 6, n_max = 76) %>%
    rename(subsector_level2 = "..2",
         subsector_level3 = "..3") %>%
  select(-`Greenhouse Gas Categories`) %>%
  select(subsector_level2, subsector_level3, everything())

## Filter if NA present in both subsector_level2 & subsector_level3
## Filter subsector_level1 from subsector_level2

## Get the emission categories for joining
catfile <- "emission_categories.csv"
cats <- read_csv(file.path(dir, catfile))






## Save the re-formatted data as CSV file
# write_csv(data_wide, (file.path(dir, paste0(data_year, "_bc_ghg_emissions.csv"))))
# write_csv(metadata, (file.path(dir, paste0(data_year, "bc_ghg_emissions_metadata.csv"))))


