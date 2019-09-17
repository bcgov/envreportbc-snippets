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


## Load libraries
library(readr) #load data from BC Data Catalogue
library(readxl) #load xlsx files
library(dplyr) # data munging
library(dataCompareR) # compare dataframes

source("R/functions.R")

## Load historical datset from the BC Data Catalogue, distributed under the
## Open Government Licence - British Columbia:
## https://catalogue.data.gov.bc.ca/dataset/d3651b8c-f560-48f7-a34e-26b0afc77d84

## communities
hist_bcsee_com <- read_csv("https://catalogue.data.gov.bc.ca/dataset/d3651b8c-f560-48f7-a34e-26b0afc77d84/resource/bbacd6fb-6708-4cf8-b353-0dc5ef75b7b9/download/bcseecommunities.csv", col_types = cols(.default = col_character()), na = c("","NA")) %>%
  mutate_at(vars(ends_with("Date")), as.Date)

## plants & animals
hist_bcsee_pa <- read_csv("https://catalogue.data.gov.bc.ca/dataset/d3651b8c-f560-48f7-a34e-26b0afc77d84/resource/39aa3eb8-da10-49c5-8230-a3b5fd0006a9/download/bcseeplantsanimals.csv", col_types = cols(.default = col_character()), na = c("","NA")) %>%
  mutate_at(vars(ends_with("Date")), as.Date)

## Year of annual snapshot you are adding - update each time
Add_Year <- "2018"

## Load annual snapshot .xlsx data files from data/ folder & add Year
annual_snapshot_com <- paste0(Add_Year, "_Communities.xlsx")
annual_snapshot_p <- paste0(Add_Year, "_Plants.xlsx")
annual_snapshot_a <- paste0(Add_Year, "_Animals.xlsx")

sheet_format <- . %>%
  mutate(Year = Add_Year) %>%
  mutate_at(vars(ends_with("Date")), to_date_from_excel) %>%
  select(Year, everything())

new_com <- read_excel(file.path("process-bcsee-data/data", annual_snapshot_com),
                      sheet = "bcsee_export", col_types = "text") %>%
  sheet_format() %>%
  select(-Kingdom, -`Name Category`)

# Drop columns which are all NA
new_com <- new_com[sapply(new_com, function(x) !all(is.na(x)))]

new_p <- read_excel(file.path("process-bcsee-data/data", annual_snapshot_p),
                     sheet = "bcsee_export", col_types = "text") %>%
  sheet_format()

new_a <- read_excel(file.path("process-bcsee-data/data", annual_snapshot_a),
                     sheet = "bcsee_export", col_types = "text") %>%
  sheet_format()

new_pa <- bind_rows(new_a, new_p)

new_pa <- new_pa[sapply(new_pa, function(x) !all(is.na(x)))]


## Make sure columns in 'new_' and 'hist_bcsee' dataframes are the same
## using the dataCompareR package
##(https://cran.r-project.org/web/packages/dataCompareR/index.html)

compare_com <- rCompare(new_com, hist_bcsee_com)
summary(compare_com)

# Change old names to new names
hist_bcsee_com <- rename(hist_bcsee_com,
                         "BGC" = "Biogeoclimatic Units",
                         "Forest Dist" = "Forest District",
                         "Provincial FRPA" = "Identified Wildlife")

compare_pa <- rCompare(new_pa, hist_bcsee_pa)
summary(compare_pa)

hist_bcsee_pa <- rename(hist_bcsee_pa, "Provincial FRPA" = "Identified Wildlife")


## Add new year data to historical dataset and export as CSV

if (!exists("process-bcsee-data/out")) dir.create("process-bcsee-data/out", showWarnings = FALSE)

combined_bcsee_com <- bind_rows(hist_bcsee_com, new_com)

write_csv(combined_bcsee_com,
          path = "process-bcsee-data/out/BCSEE_Communities.csv",
          na = "", append = FALSE)

combined_bcsee_pa <- bind_rows(hist_bcsee_pa, new_pa)

write_csv(combined_bcsee_pa,
          path = "process-bcsee-data/out/BCSEE_Plants_Animals.csv",
          na = "", append = FALSE)
