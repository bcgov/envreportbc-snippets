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
library(glue)

## Import the .xlsx table from data/
dir <- "process-ghg-pi-table/data"
filename <- "2017_provincal_inventory.xlsx"

download.file("https://www2.gov.bc.ca/assets/gov/environment/climate-change/data/provincial-inventory/2017/2017_provincial_inventory.xlsx",
              destfile = file.path(dir, filename))

## Get the metadata from the sheet
units <- read_xlsx(file.path(getwd(),dir, filename),
                   col_names = c("Note", "blank1", "blank2", "Comment"),
                   range = cell_rows(5)) %>%
  select(Note, Comment)

metadata <- read_xlsx(file.path(getwd(),dir, filename),
                      col_names = c("Note","Comment"),
                      range = cell_rows(90:97)) %>%
  rbind(units)


## Get the subsector level 1 emission categories from previous published data
## provided under the OGL-BC licence in the B.C. Data Catalogue as a helper
## https://catalogue.data.gov.bc.ca/dataset/24c899ee-ef73-44a2-8569-a0d6b094e60c

level1 <- read_csv("https://catalogue.data.gov.bc.ca/dataset/24c899ee-ef73-44a2-8569-a0d6b094e60c/resource/11b1da01-fabc-406c-8b13-91e87f126dec/download/bcghgemissions.csv",
                       na=c("-","","NA")) %>%
  mutate(subsector_level1 = recode(subsector_level1,
                                   `Production and Consumption of Halocarbons, SF6 and NF3` = "Production and Consumption of Halocarbons, SF6 and NF33",
                                   `Agriculture Soils` = "Agricultural Soils",
                                   `Wastewater Handling` = "Wastewater Treatment and Discharge",
                                   `Waste Incineration` = "Incineration and Open Burning of Waste")) %>%
  pull(subsector_level1) %>%
  unique()

## Create some similar helper vectors of emission categories
level1_only <- c("CO2 Transport and Storage", "Production and Consumption of Halocarbons, SF6 and NF33", "Non-Energy Products from Fuels and Solvent Use", "Other Product Manufacture and Use",  "Enteric Fermentation",  "Manure Management", "Field Burning of Agricultural Residues", "Liming, Urea Application and Other Carbon-containing Fertilizers",  "Solid Waste Disposal", "Biological Treatment of Solid Waste", "Wastewater Treatment and Discharge", "Incineration and Open Burning of Waste", "Deforestation", "Afforestation", "Grassland converted to Cropland", "Other Land converted to Wetlands", "Cropland Management","Wetland Management", "Grassland Management", "Settlement Management")

level3_to_2 <- c("Cement Production", "Lime Production", "Mineral Products Use", "Adipic Acid Production", "Iron and Steel Production", "Aluminum Production", "SF6 Used in Magnesium Smelters and Casters", "Direct Sources","Indirect Sources")

level3_transport <- c("Road Transportation", "Other Transportation")

road_transport <- c("Light-Duty Gasoline Vehicles", "Light-Duty Gasoline Trucks", "Heavy-Duty Gasoline Vehicles", "Motorcycles", "Light-Duty Diesel Vehicles", "Light-Duty Diesel Trucks", "Heavy-Duty Diesel Vehicles", "Propane and Natural Gas Vehicles")

other_transport <- c("Off-Road Agriculture & Forestry", "Off-Road Commercial & Institutional", "Off-Road Manufacturing, Mining & Construction", "Off-Road Residential", "Off-Road Other Transportation", "Pipeline Transport")

oil_gas <- c("Oil", "Natural Gas", "Venting", "Flaring")

## Get the column names
newcols <- colnames(read_xlsx(file.path(dir, filename),
                              col_names = TRUE, skip = 1))


## Get the core data, wrangle the 3 attribute columns
## into the official sector & 3 subsector columns, and filter out derived rows

data_wide <- read_xlsx(file.path(dir, filename),
                       col_names = newcols,
                       skip = 6, n_max = 81) %>%
  rename(sector = "Greenhouse Gas Categories",
         subsector_level2 = "...2",
         subsector_level3 = "...3") %>%
  mutate(sector =  str_replace(sector, "[a-z]\\.", NA_character_),
         subsector_level2 = recode(subsector_level2,
                                   `Transport1` = "Transport",
                                   `Chemical Industry2` = "Chemical Industry")) %>%
  mutate(subsector_level1 = case_when(
    subsector_level2 %in% level1 ~ subsector_level2)) %>%
  select(sector, subsector_level1, subsector_level2, subsector_level3, everything()) %>%
  fill(sector) %>%
  filter_at(vars(subsector_level1, subsector_level2, subsector_level3),
            any_vars(!is.na(.))) %>%
  mutate(subsector_level2 = case_when(subsector_level2 %in% level1_only ~ NA_character_,
                                  TRUE ~ subsector_level2)) %>%
  fill(subsector_level1) %>%
  filter(subsector_level1 != subsector_level2 | is.na(subsector_level2)) %>%
  mutate(subsector_level2 = case_when(subsector_level3 %in% level3_to_2 ~ subsector_level3,
                                      !(subsector_level2 %in% level3_to_2) ~ subsector_level2),
         subsector_level3 = case_when(subsector_level3 %in% level3_to_2 ~ NA_character_,
                                   TRUE ~ subsector_level3)) %>%
  filter(!subsector_level2 %in% level3_transport | is.na(subsector_level2)) %>%
  mutate(subsector_level2 = case_when(subsector_level3 %in% road_transport ~ "Road Transportation",
                                     (subsector_level3 %in% other_transport) ~ "Other Transportation",
                                     TRUE ~ subsector_level2)) %>%
  mutate(subsector_level2 = case_when(subsector_level3 %in% oil_gas ~ "Oil and Natural Gas",
                                      TRUE ~ subsector_level2)) %>%
  select(-c("...32", "2007-2017 (10-year trend)","2016-2017 change (gross)","3-year trend")) %>%
#  filter(!subsector_level2 %in% oil_gas | is.na(subsector_level2))
  mutate_at(vars(-sector, -subsector_level1, -subsector_level2, -subsector_level3),
            funs(round(as.numeric(.), digits = 2)))

# quick fix to remove the NA "oil and Gas totals row"
 data_wide <- data_wide[-28,]


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


## compare rstats totals with xlsx table totals
sector_list <- c("ENERGY", "INDUSTRIAL PROCESSES AND PRODUCT USE", "AGRICULTURE", "WASTE", "Afforestation and Deforestation")

compare_xls_totals <- read_xlsx(file.path(dir, filename),
                       col_names = newcols,
                       skip = 6, n_max = 81) %>%
  filter(`Greenhouse Gas Categories` %in% sector_list) %>%
  rename(sector = `Greenhouse Gas Categories`) %>%
  select(-"...2", -"...3") %>%
  gather(key = year, value = ktCO2e, -sector) %>%
  mutate(ktCO2e = round(as.numeric(ktCO2e), digits = 0),
         year = as.integer(as.character(year))) %>%
  left_join(sector_totals) %>%
  mutate(diff = ktCO2e - sum)


## Save the re-formatted data as CSV file
data_year <- "2017"
write_csv(data_wide, (file.path(dir, glue(data_year, "_bc_ghg_emissions.csv"))))
write_csv(metadata, (file.path(dir, glue(data_year, "_bc_ghg_emissions_metadata.csv"))))


