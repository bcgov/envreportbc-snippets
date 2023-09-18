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
newcols <- c("gas","all_sectors", colnames(read_xlsx(file.path(dir, filename),
                                               col_names = TRUE, range = "Gases!D3:AI3")))


#Get gas, sector, subsector 1 & 2 & 3
formats <- xlsx_formats(file.path(dir, filename))

sector_cell_formats <- xlsx_cells(file.path(dir, filename),
                                  sheets = "Gases",
                                  include_blank_cells = FALSE) %>%
  filter(between(col,2,3), between(row, 5, 552) | between(row, 525, 601)) %>%
  select(address, row, col, all_sectors = character, local_format_id) %>%
  mutate(
    all_sectors = gsub("^\\s+|\\s+$", "", all_sectors),
    text_colour = map_chr(local_format_id, ~ formats$local$font$color$rgb[[.x]]),
    bg_colour = map_chr(local_format_id, ~ formats$local$fill$patternFill$bgColor$rgb[[.x]]),
    bold = map_lgl(local_format_id, ~ formats$local$font$bold[[.x]]),
    indent = map_int(local_format_id, ~ formats$local$alignment$indent[[.x]]),
    sector_level = case_when(
      is.na(text_colour) & is.na(bg_colour) & bold & indent == 0 ~ "gas",
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
                       range = "Gases!B5:AI522",
                       na = c("", "-")) %>%
  mutate(row = seq(5, length.out = nrow(.))) %>%
  bind_rows(
   read_xlsx(file.path(dir, filename),
              col_names = newcols,
              range = "Gases!B525:AI601",
              na = c("", "-")) %>%
      mutate(row = seq(525, length.out = nrow(.)))
  ) %>%
  left_join(
    sector_cell_formats %>%
      select(row, all_sectors, sector_level),
    by = c("row", "all_sectors")
  ) %>%
  fill(gas) %>%
  filter(!is.na(all_sectors)) %>%
  mutate(all_sectors =  gsub("[0-9]$", "", all_sectors)) %>%
  pivot_wider(names_from = sector_level, values_from = all_sectors) %>%
  mutate(
    subsector_level1 = ifelse(!is.na(sector), "total", subsector_level1),
    subsector_level2 = ifelse(!is.na(subsector_level1), NA_character_, subsector_level2),
    subsector_level1 = ifelse(subsector_level1 == "OTHER LAND USE", "Other Emissions Not Included In Inventory Total", subsector_level1)
  ) %>%
  fill(sector, subsector_level1, subsector_level2) %>%
  filter(sector != "total" & subsector_level1 != "total") %>%
  group_by(gas, sector, subsector_level1, subsector_level2) %>%
  mutate(n = n()) %>%
  ungroup() %>%
  filter(n == 1 | (!is.na(subsector_level3) & n > 1)) %>%
  filter(!is.na(subsector_level2)) %>%
  select(gas,sector, subsector_level1, subsector_level2, subsector_level3, `1990`:`2021`)

## Testing to make sure sums are same as input table
data_long <- data_wide %>%
  gather(key =  year, value = ktCO2e, -gas,
         -sector, -subsector_level1,
         -subsector_level2, -subsector_level3) %>%
  mutate(ktCO2e = as.numeric(ktCO2e),
         year = as.integer(as.character(year)))

totals <- data_long %>%
  filter(subsector_level1 != "Other Emissions Not Included In Inventory Total") %>%
  group_by(gas, year) %>%
  summarise(sum = round(sum(ktCO2e, na.rm=TRUE), digits = 0))
totals

sector_totals <- data_long %>%
  filter(subsector_level1 != "Other Emissions Not Included In Inventory Total") %>%
  group_by(gas, sector, subsector_level1, year) %>%
  summarise(sum = round(sum(ktCO2e, na.rm=TRUE), digits = 1)) %>%
  mutate(year = as.integer(as.character(year))) %>%
  filter(!is.na(year))

sector_totals

## Save the re-formatted data as CSV file
data_year_range <- range(data_long$year)
fname <- paste0("bc_ghg_emissions_by_economic_sector_by_gas_", data_year_range[1], "-", data_year_range[2], ".csv")
write_csv(data_wide, (file.path(dir, fname)))
cat(
  paste0("\n## GHGs by Economic Sector (", fname, ")\n"),
  replace_na(metadata$Notes, ""),
  file = file.path(dir, paste0("bc_ghg_emissions_by_gas_", data_year_range[1], "-", data_year_range[2], "_metadata.txt")),
  sep = "\n",
  append = TRUE
)

