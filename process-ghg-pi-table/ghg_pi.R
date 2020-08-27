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
library(readr)
library(stringr)
library(tidyr)
library(glue)
library(purrr)

## Import the .xlsx table from data/
dir <- "process-ghg-pi-table/data"
filename <- "bc_provincial_ghg_inventory_1990-2018.xlsx"

# download.file("https://www2.gov.bc.ca/assets/gov/environment/climate-change/data/provincial-inventory/2017/2017_provincial_inventory.xlsx",
#               destfile = file.path(dir, filename))

## Get the metadata from the sheet
units <- read_xlsx(file.path(getwd(),dir, filename),
                   col_names = c("Notes"),
                   range = "Activity Categories!B3")

metadata <- read_xlsx(file.path(getwd(),dir, filename),
                      col_names = c("Notes"),
                      range = cell_rows(91:98)) %>%
  rbind(units)

## Get the column names
newcols <- c("all_sectors", colnames(read_xlsx(file.path(dir, filename),
                                          col_names = TRUE, range = "C3:AE3")))

## Get the core data, wrangle the 3 attribute columns
## into the official sector & 3 subsector columns, and filter out total rows

# extract cell formatting to deduce sector/subsector level
formats <- xlsx_formats(file.path(dir, filename))

sector_cell_formats <- xlsx_cells(file.path(dir, filename),
           sheets = "Activity Categories",
           include_blank_cells = FALSE) %>%
  filter(col == 2, between(row, 5, 76) | between(row, 79, 88)) %>%
  select(address, row, col, all_sectors = character, local_format_id) %>%
  mutate(
    all_sectors = gsub("^\\s+|\\s+$", "", all_sectors),
    text_colour = map_chr(local_format_id, ~ formats$local$font$color$rgb[[.x]]),
         bg_colour = map_chr(local_format_id, ~ formats$local$fill$patternFill$bgColor$rgb[[.x]]),
         bold = map_lgl(local_format_id, ~ formats$local$font$bold[[.x]]),
         indent = map_int(local_format_id, ~ formats$local$alignment$indent[[.x]]),
         sector_level = case_when(
           is.na(text_colour) & bg_colour == "FFFFFFFF" & bold & indent == 0 ~ "sector",
           text_colour == "FF00783C" & bold & indent == 0 ~ "subsector_level1",
           !bold & indent == 1 ~ "subsector_level2",
           text_colour == "FFFFFFFF" & !bold & indent == 3 ~ "subsector_level3",
           TRUE ~ "ahhhh"
         )
  )


# Join sector level info with data, filter out total rows
data_wide <- read_xlsx(file.path(dir, filename),
                       col_names = newcols,
                       range = "B5:AE76",
                       na = c("", "-")) %>%
  mutate(row = seq(5, length.out = nrow(.))) %>%
  bind_rows(
    read_xlsx(file.path(dir, filename),
                      col_names = newcols,
                      range = "B79:AE88",
                      na = c("", "-")) %>%
      mutate(row = seq(79, length.out = nrow(.)))
    ) %>%
  left_join(
    sector_cell_formats %>%
      select(row, all_sectors, sector_level),
    by = c("row", "all_sectors")
  ) %>%
  mutate(all_sectors =  str_replace(all_sectors, "[0-9]$", "")) %>%
  pivot_wider(names_from = sector_level, values_from = all_sectors) %>%
  mutate(
    subsector_level1 = ifelse(!is.na(sector), "total", subsector_level1),
    subsector_level2 = ifelse(!is.na(subsector_level1), "total", subsector_level2),
    subsector_level3 = ifelse(!is.na(subsector_level2), NA_character_, subsector_level3),
    sector = ifelse(subsector_level1 == "OTHER LAND USE", "Other Emissions Not Included In Inventory Total", sector)
  ) %>%
  fill(sector, subsector_level1, subsector_level2) %>%
  filter(sector != "total" & subsector_level1 != "total" & subsector_level2 != "total") %>%
  group_by(sector, subsector_level1, subsector_level2) %>%
  mutate(n = n()) %>%
  ungroup() %>%
  filter(n == 1 | (!is.na(subsector_level3) & n > 1)) %>%
  select(sector, subsector_level1, subsector_level2, subsector_level3, `1990`:`2018`)

## Testing to make sure sums are same as input table
data_long <- data_wide %>%
  gather(key =  year, value = ktCO2e,
         -sector, -subsector_level1,
         -subsector_level2, -subsector_level3) %>%
  mutate(ktCO2e = as.numeric(ktCO2e),
         year = as.integer(as.character(year)))

totals <- data_long %>%
  filter(sector != "OTHER LAND USE (Not included in total B.C. emissions)") %>%
  group_by(year) %>%
  summarise(sum = round(sum(ktCO2e, na.rm=TRUE), digits = 0))
totals

sector_totals <- data_long %>%
  filter(sector != "OTHER LAND USE (Not included in total B.C. emissions)") %>%
  group_by(sector, year) %>%
  summarise(sum = round(sum(ktCO2e, na.rm=TRUE), digits = 0)) %>%
  mutate(year = as.integer(as.character(year))) %>%
  filter(!is.na(year))

sector_totals

## Save the re-formatted data as CSV file
data_year <- "2018"
write_csv(data_wide, (file.path(dir, glue(data_year, "_bc_ghg_emissions.csv"))))
write_csv(metadata, (file.path(dir, glue(data_year, "_bc_ghg_emissions_metadata.csv"))))
