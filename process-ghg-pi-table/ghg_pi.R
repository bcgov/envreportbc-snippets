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


## Get the subsector level 1 emission categories from the B.C. Data Catalogue as a helper
## Data is here https://catalogue.data.gov.bc.ca/dataset/24c899ee-ef73-44a2-8569-a0d6b094e60c
## provided under the OGL-BC licence
level1 <- read_csv("https://catalogue.data.gov.bc.ca/dataset/24c899ee-ef73-44a2-8569-a0d6b094e60c/resource/11b1da01-fabc-406c-8b13-91e87f126dec/download/bcghgemissions.csv",
                   na=c("-","","NA")) %>%
  mutate(subsector_level1 = recode(subsector_level1,
                                   `Production and Consumption of Halocarbons, SF6 and NF3` = "Production and Consumption of Halocarbons, SF6 and NF33",
                                   `Agriculture Soils` = "Agricultural Soils")) %>%
  pull(subsector_level1) %>%
  unique()

## Create some similar helper vectors of emission categories
level1_only <- c("CO2 Transport and Storage", "Production and Consumption of Halocarbons, SF6 and NF33", "Non-Energy Products from Fuels and Solvent Use", "Other Product Manufacture and Use",  "Enteric Fermentation",  "Manure Management", "Field Burning of Agricultural Residues", "Liming, Urea Application and Other Carbon-containing Fertilizers",  "Solid Waste Disposal", "Biological Treatment of Solid Waste", "Wastewater Handling", "Waste Incineration", "Deforestation", "Afforestation", "Grassland converted to Cropland", "Other Land converted to Wetlands", "Cropland Management","Wetland Management", "Grassland Management", "Settlement Management")

level3_to_2 <- c("Cement Production", "Lime Production", "Mineral Products Use", "Adipic Acid Production", "Iron and Steel Production", "Aluminum Production", "SF6 Used in Magnesium Smelters and Casters", "Direct Sources","Indirect Sources")

level3_transport <- c("Road Transportation", "Other Transportation")

road_transport <- c("Light-Duty Gasoline Vehicles", "Light-Duty Gasoline Trucks", "Heavy-Duty Gasoline Vehicles", "Motorcycles", "Light-Duty Diesel Vehicles", "Light-Duty Diesel Trucks", "Heavy-Duty Diesel Vehicles", "Propane and Natural Gas Vehicles")

other_transport <- c("Off-Road Agriculture & Forestry", "Off-Road Commercial & Institutional", "Off-Road Manufacturing, Mining & Construction", "Off-Road Residential", "Off-Road Other Transportation", "Pipeline Transport")


## Get the first the column names
newcols <- colnames(read_xlsx(file.path(dir, filename),
                              col_names = TRUE, skip = 1))


## Get the core data, wrangle the 3 attribute columns
## into the official sector & 3 subsector columns, and filter out derived rows

data_wide <- read_xlsx(file.path(dir, filename),
                       col_names = newcols,
                       skip = 7, n_max = 76) %>%
  rename(sector = "Greenhouse Gas Categories",
         subsector_level2 = "..2",
         subsector_level3 = "..3") %>%
  mutate(sector =  str_replace(sector, "[a-z]\\.", NA_character_),
         subsector_level2 = recode(subsector_level2,
                                   `Transport1` = "Transport",
                                   `Chemical Industry2` = "Chemical Industry")) %>%
  mutate(subsector_level1 = case_when(subsector_level2 %in% level1 ~ subsector_level2)) %>%
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
                                     TRUE ~ subsector_level2))


## Testing to make sure sums are same as ipout table
data_long <- reshape2::melt(data_wide, id.vars=c("sector","subsector_level1","subsector_level2","subsector_level3"),variable.name="year", value.name="ktCO2e") %>%
  mutate(ktCO2e = as.numeric(ktCO2e),
         year = as.integer(as.character(year)))

foo <-

totals <- data_long %>%
  filter(sector != "OTHER LAND USE (Not included in total B.C. emissions)") %>%
  group_by(year) %>%
  summarise(sum = sum(ktCO2e, na.rm=TRUE))
totals

sector <- data_long %>%
  filter(sector != "OTHER LAND USE (Not included in total B.C. emissions)") %>%
  group_by(sector, year) %>%
  summarise(sum = sum(ktCO2e, na.rm=TRUE))
sector

## Save the re-formatted data as CSV file
# write_csv(data_wide, (file.path(dir, paste0(data_year, "_bc_ghg_emissions.csv"))))
# write_csv(metadata, (file.path(dir, paste0(data_year, "bc_ghg_emissions_metadata.csv"))))

