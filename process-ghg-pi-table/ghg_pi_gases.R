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
library(dplyr)
library(tidyr)
library(purrr)
library(readr)

## Manually download the .xlsx table from the following URL:
## https://www2.gov.bc.ca/assets/gov/environment/climate-change/data/provincial-inventory/2021/provincial_inventory_of_greenhouse_gas_emissions_1990-2021.xlsx

## Import the .xlsx table from data/
dir <- "process-ghg-pi-table/data"
filename <- 'provincial_inventory_of_greenhouse_gas_emissions_1990-2021_edited.xlsx'

## Get the metadata from the sheet
units <- readxl::read_xlsx(file.path(getwd(),dir, filename),
                           col_names = c("Notes"),
                           range = "Gases!B3")

metadata <- read_xlsx(file.path(getwd(),dir, filename),
                      col_names = c("Notes"),
                      range = "Gases!C604:C618") %>%
  filter(!grepl("Indicates no emissions", Notes)) %>%
  rbind(units)

## Get the column names
newcols <- c("all_sectors", colnames(read_xlsx(file.path(dir, filename),
                                               col_names = TRUE, range = "Gases!D3:AI3")))


#Get gas, sector, subsector 1 & 2 & 3
formats <- xlsx_formats(file.path(dir, filename))

sector_cell_formats <- xlsx_cells(file.path(dir, filename),
                                  sheets = "Gases",
                                  include_blank_cells = FALSE) %>%
  filter(col == 3, between(row, 5, 552) | between(row, 525, 601)) %>%
  select(address, row, col, all_sectors = character, local_format_id) %>%
  mutate(
    all_sectors = gsub("^\\s+|\\s+$", "", all_sectors),
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
  )
