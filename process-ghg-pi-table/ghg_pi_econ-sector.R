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
library(tidyxl)
library(tidyverse)
library(openxlsx)
library(dplyr)
library(tidyr)
library(purrr)
library(readr)

## IMPORTANT: for now, I can't get the automatic XLSX download to work. Directly reading the excel file
## does work, but drops the formatting. To properly identify category levels (i.e. main category, subcategory, sub-subcategory, etc.),
## you must download the excel file from here: https://www2.gov.bc.ca/assets/gov/environment/climate-change/data/provincial-inventory/2020/provincial_inventory_of_greenhouse_gas_emissions_1990-2020.xlsx
## and place it somewhere, e.g. your Downloads folder, as I did.


## Import the .xlsx table from data/
dir <- "process-ghg-pi-table/data"
filename <- "provincial_inventory_of_greenhouse_gas_emissions_economic_sectors_1990-2020.xlsx"

prov_inv = openxlsx::read.xlsx("https://www2.gov.bc.ca/assets/gov/environment/climate-change/data/provincial-inventory/2020/provincial_inventory_of_greenhouse_gas_emissions_1990-2020.xlsx",
                               startRow = 3,
                               sheet = 'Economic Sectors') %>%
  as_tibble() %>%
  distinct()

write.xlsx(prov_inv, paste(dir,filename, sep = '/'), overwrite = T)

# Grab the units from the original column name of column A.
units = str_remove(names(prov_inv)[1], "Unit:\\.")

# Improve readability of column names.
prov_inv = prov_inv %>%
  setNames(c('ghg_category',paste0('year_',1990:2020),
           'comp_2007_2020_1','comp_2007_2020_2',
           'comp_2019_2020_1','comp_2019_2020_2',
           'three_year_trend_1','three_year_trend_2'))

metadata = prov_inv %>%
  slice((which(ghg_category == 'Notes:')+1):nrow(.)) %>%
  rename(notes = ghg_category) %>%
  dplyr::select(notes)

## Get the core data, wrangle the 3 attribute columns
## into the official sector & 3 subsector columns, and filter out total rows

formats <- xlsx_formats('C:/Users/CMADSEN/Downloads/provincial_inventory_of_greenhouse_gas_emissions_1990-2020.xlsx')

sector_cell_formats = xlsx_cells('C:/Users/CMADSEN/Downloads/provincial_inventory_of_greenhouse_gas_emissions_1990-2020.xlsx',
                                  sheets = "Economic Sectors",
                                  include_blank_cells = FALSE) %>%
  filter(col == 2, between(row, 5, 51) | between(row, 54, 63)) %>%
  select(address, row, col, ghg_category = character, local_format_id) %>%
  mutate(
    ghg_category = gsub("^\\s+|\\s+$", "", ghg_category),
    text_colour = map_chr(local_format_id, ~ formats$local$font$color$rgb[[.x]]),
    bg_colour = map_chr(local_format_id, ~ formats$local$fill$patternFill$bgColor$rgb[[.x]]),
    bold = map_lgl(local_format_id, ~ formats$local$font$bold[[.x]]),
    indent = map_int(local_format_id, ~ formats$local$alignment$indent[[.x]]),
    sector_level = case_when(
      text_colour == "FF00783C" & bold & indent == 0 ~ "sector",
      !bold & indent == 1 ~ "subsector_level1",
      text_colour == "FFFFFFFF" & !bold & (indent == 2 | indent ==3) ~ "subsector_level2",
      TRUE ~ "ahhhh"
    )
  ) %>%
  dplyr::select(ghg_category, sector_level)

prov_inv = prov_inv %>%
  #Remove the total.
  filter(ghg_category != 'TOTAL1') %>%
  #Use the sector_cell_formats object to set category levels.
  left_join(sector_cell_formats) %>%
  dplyr::select(sector_level, everything()) %>%
  filter(year_1990 != "")

write.csv(prov_inv, file.path(dir,'bc_ghg_emissions_by_economic_sector_1990-2020.csv'),
          row.names = F)

# Copy these results into the GHG indicator folder, if you have it on your local machine.
my_base_dir = str_remove(getwd(),'envreportbc-snippets')
if(dir.exists(paste0(my_base_dir,'ghg-emissions-indicator/tmp'))){
  file.copy(from = file.path(dir,'bc_ghg_emissions_by_economic_sector_1990-2020.csv'),
            to = paste0(my_base_dir,'ghg-emissions-indicator/tmp/bc_ghg_emissions_by_economic_sector_1990-2020.csv'),
            overwrite = T)
}
