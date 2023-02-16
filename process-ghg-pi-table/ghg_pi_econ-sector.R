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


## Manually download the .xlsx table from the following URL:
## https://www2.gov.bc.ca/assets/gov/environment/climate-change/data/provincial-inventory/2020/provincial_inventory_of_greenhouse_gas_emissions_1990-2020.xlsx

## Import the .xlsx table from data/
dir <- "process-ghg-pi-table/data"
filename <- 'provincial_inventory_of_greenhouse_gas_emissions_1990-2020.xlsx'

## Get the metadata from the sheet
units <- readxl::read_xlsx(file.path(getwd(),dir, filename),
                   col_names = c("Notes"),
                   range = "Economic Sectors!B3")


# Improve readability of column names.
prov_inv = prov_inv %>%
  setNames(c('ghg_category',paste0('year_',1990:2020),
           'comp_2007_2020_1','comp_2007_2020_2',
           'comp_2019_2020_1','comp_2019_2020_2',
           'three_year_trend_1','three_year_trend_2'))


## Get the column names
newcols <- c("all_sectors", colnames(read_xlsx(file.path(dir, filename),
                                               col_names = TRUE, range = "Economic Sectors!C3:AG3")))


## Get the core data, wrangle the 3 attribute columns
## into the official sector & 3 subsector columns, and filter out total rows

formats <- xlsx_formats('provincial_inventory_of_greenhouse_gas_emissions_1990-2020.xlsx')

sector_cell_formats = xlsx_cells('provincial_inventory_of_greenhouse_gas_emissions_1990-2020.xlsx',
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

  )


# Join sector level info with data, filter out total rows
data_wide <- read_xlsx(file.path(dir, filename),
                       col_names = newcols,
                       range = "Economic Sectors!B5:AG51",
                       na = c("", "-")) %>%
  mutate(row = seq(5, length.out = nrow(.))) %>%
  bind_rows(
    read_xlsx(file.path(dir, filename),
              col_names = newcols,
              range = "Economic Sectors!B54:AG63",
              na = c("", "-")) %>%
      mutate(row = seq(54, length.out = nrow(.)))
  ) %>%
  left_join(
    sector_cell_formats %>%
      select(row, all_sectors, sector_level),
    by = c("row", "all_sectors")
  ) %>%
  mutate(all_sectors =  gsub("[0-9]$", "", all_sectors)) %>%
  pivot_wider(names_from = sector_level, values_from = all_sectors) %>%
  mutate(
    subsector_level1 = ifelse(!is.na(sector), "total", subsector_level1),
    subsector_level2 = ifelse(!is.na(subsector_level1), NA_character_, subsector_level2),
    sector = ifelse(sector == "OTHER LAND USE", "Other Emissions Not Included In Inventory Total", sector)
  ) %>%
  fill(sector, subsector_level1) %>%
  filter(sector != "total" & subsector_level1 != "total") %>%
  group_by(sector, subsector_level1) %>%
  mutate(n = n()) %>%
  ungroup() %>%
  filter(n == 1 | (!is.na(subsector_level2) & n > 1)) %>%
  select(sector, subsector_level1, subsector_level2, `1990`:`2020`)

## Testing to make sure sums are same as input table
data_long <- data_wide %>%
  gather(key =  year, value = ktCO2e,
         -sector, -subsector_level1,
         -subsector_level2) %>%
  mutate(ktCO2e = as.numeric(ktCO2e),
         year = as.integer(as.character(year)))

totals <- data_long %>%
  filter(sector != "Other Emissions Not Included In Inventory Total") %>%
  group_by(year) %>%
  summarise(sum = round(sum(ktCO2e, na.rm=TRUE), digits = 0))
totals

sector_totals <- data_long %>%
  filter(sector != "Other Emissions Not Included In Inventory Total") %>%
  group_by(sector, year) %>%
  summarise(sum = round(sum(ktCO2e, na.rm=TRUE), digits = 0)) %>%
  mutate(year = as.integer(as.character(year))) %>%
  filter(!is.na(year))

sector_totals

## Save the re-formatted data as CSV file
data_year_range <- range(data_long$year)
fname <- paste0("bc_ghg_emissions_by_economic_sector_", data_year_range[1], "-", data_year_range[2], ".csv")
write_csv(data_wide, (file.path(dir, fname)))
cat(
  paste0("\n## GHGs by Economic Sector (", fname, ")\n"),
  replace_na(metadata$Notes, ""),
  file = file.path(dir, paste0("bc_ghg_emissions_", data_year_range[1], "-", data_year_range[2], "_metadata.txt")),
  sep = "\n",
  append = TRUE
)
