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

## Import the .xlsx table from data/
dir <- "process-ghg-pi-table/data"
filename <- "bc_provincial_ghg_inventory_1990-2018.xlsx"

# download.file("https://www2.gov.bc.ca/assets/gov/environment/climate-change/data/provincial-inventory/2017/2017_provincial_inventory.xlsx",
#               destfile = file.path(dir, filename))

## Get the metadata from the sheet
units <- read_xlsx(file.path(getwd(),dir, filename),
                   col_names = c("Notes"),
                   range = "Economic Sectors!B3")

metadata <- read_xlsx(file.path(getwd(),dir, filename),
                      col_names = c("Notes"),
                      range = "Economic Sectors!B66:B71") %>%
  filter(!grepl("Indicates no emissions", Notes)) %>%
  rbind(units)

## Get the column names
newcols <- c("all_sectors", colnames(read_xlsx(file.path(dir, filename),
                                               col_names = TRUE, range = "Economic Sectors!C3:AE3")))

## Get the core data, wrangle the 3 attribute columns
## into the official sector & 3 subsector columns, and filter out total rows

# extract cell formatting to deduce sector/subsector level
formats <- xlsx_formats(file.path(dir, filename))

sector_cell_formats <- xlsx_cells(file.path(dir, filename),
                                  sheets = "Economic Sectors",
                                  include_blank_cells = FALSE) %>%
  filter(col == 2, between(row, 5, 51) | between(row, 54, 63)) %>%
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


# Join sector level info with data, filter out total rows
data_wide <- read_xlsx(file.path(dir, filename),
                       col_names = newcols,
                       range = "Economic Sectors!B5:AE51",
                       na = c("", "-")) %>%
  mutate(row = seq(5, length.out = nrow(.))) %>%
  bind_rows(
    read_xlsx(file.path(dir, filename),
              col_names = newcols,
              range = "Economic Sectors!B54:AE63",
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
  select(sector, subsector_level1, subsector_level2, `1990`:`2018`)

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
data_year <- "2018"
write_csv(data_wide, (file.path(dir, paste0(data_year, "_bc_ghg_emissions_by_economic_sector.csv"))))
write_csv(metadata, (file.path(dir, paste0(data_year, "_bc_ghg_emissions_by_economic_sector_metadata.csv"))))
