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
library(stringr)
library(tidyr)


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


## Get the emission categories as a helper
catfile <- "emission_categories.csv"
cats <- read_csv(file.path(dir, catfile))

level1 <- unique(cats$subsector_level1)

## Get the column names
newcols <- colnames(read_xlsx(file.path(dir, filename),
                              col_names = TRUE, skip = 1))

## Get the core data
## without the title, empty leading rows & metadata
## add new column names

data <- read_xlsx(file.path(dir, filename),
                  col_names = newcols,
                  skip = 7, n_max = 76) %>%
  rename(sector = "Greenhouse Gas Categories",
         subsector_level2 = "..2",
         subsector_level3 = "..3") %>%
  mutate(sector =  str_replace(sector, "[a-zA-Z]\\.", NA_character_),
         subsector_level2 = recode(subsector_level2,
                                   `Transport1` = "Transport",
                                   `Chemical Industry` = "Chemical Industry")) %>%
  mutate(subsector_level1 = case_when(subsector_level2 %in% level1 ~ subsector_level2)) %>%
  select(sector, subsector_level1, subsector_level2, subsector_level3, everything()) %>%
  fill(sector) %>%
  filter_at(vars(subsector_level1, subsector_level2, subsector_level3), any_vars(!is.na(.))) %>%
  fill(subsector_level1)

foo <- data %>% filter(sector == str_extract(sector, "[a-zA-Z]\\."))

fill()

## Replace subsector_level1 values that are actually subsector_level2
## values with NA



## Save the re-formatted data as CSV file
# write_csv(data_wide, (file.path(dir, paste0(data_year, "_bc_ghg_emissions.csv"))))
# write_csv(metadata, (file.path(dir, paste0(data_year, "bc_ghg_emissions_metadata.csv"))))


