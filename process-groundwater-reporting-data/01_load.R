# Copyright 2019 Province of British Columbia
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
library(envreportutils)
library(tidyr)
library(stringr)
library(lubridate)
library(gridExtra)
library(bcdata)


wfile <- file.path("process-groundwater-reporting-data/data",
                   "MASTER_Metrics for Publicly Available PGOWN Validated Data.xlsx")

#wfile <- file.path(
#  soe_path("Operations ORCS/Special Projects/Water Program/Groundwater Wells Reporting/Data"),
#  "MASTER_Metrics for Publicly Available PGOWN Validated Data.xlsx"
#)

# feb 2019
wdata_0219 <- read_excel(wfile, sheet = "Feb 2019", range = "A2:J228",
                    col_names = c("Region", "Data_graded", "Well_ID", "Location",
                                  "Date_Validated", "Months_since_val", "foo","initial_cost","foo1", "comment"),
                    col_types = c("text", "text", "text","text", "date", "text",
                                  "text", "text", "text","text")) %>%
  select(-c("foo", "foo1")) %>%
  mutate(Region = ifelse(str_detect(Region, "%"),NA ,Region),
         Region = ifelse(str_detect(Region, "Total"),NA ,Region),
         initial_cost = as.numeric(initial_cost),
         Well_ID = as.integer(gsub("^#", "", Well_ID))) %>%
  fill(Region) %>%
  filter_at(.vars = vars(Data_graded, Well_ID), .vars_predicate = any_vars(!is.na(.))) %>%
  mutate(report_data = "2019-02-01",
        dateCheck = round(interval(ymd(Date_Validated),
                                         ymd("2019-02-01"))/ months(1), 0))


# July 2018
wdata_0718 <- read_excel(wfile, sheet = "July 2018", range = "A2:J219",
                         col_names = c("Region", "Data_graded", "Well_ID", "Location",
                                       "Date_Validated", "Months_since_val", "foo","initial_cost","foo1", "comment"),
                         col_types = c("text", "text", "text","text", "date", "text",
                                       "text", "text", "text","text")) %>%
  select(-c("foo", "foo1")) %>%
  mutate(Region = ifelse(str_detect(Region, "%"),NA , Region),
         Region = ifelse(str_detect(Region, "Total"),NA ,Region),
         initial_cost = as.numeric(initial_cost),
         Well_ID = as.integer(gsub("^#", "", Well_ID))) %>%
  fill(Region) %>%
  filter_at(.vars = vars(Data_graded, Well_ID), .vars_predicate = any_vars(!is.na(.))) %>%
  mutate(report_data = "2018-07-01",
         dateCheck = round(interval(ymd(Date_Validated),
                                    ymd("2018-07-01"))/ months(1), 0))


bind_rows(wdata_0219,wdata_0718 )


# import well dataset from the data catalogue ( )

# get wells column names
bcdc_describe_feature("e4731a85-ffca-4112-8caf-cb0a96905778")

# Get the wells which have an OBSERVATION_WELL_NUMBER (and thus are part of PGOWN)
wells <- bcdc_query_geodata("e4731a85-ffca-4112-8caf-cb0a96905778") %>%
  filter(!is.na(OBSERVATION_WELL_NUMBER)) %>%
  select(WELL_LOCATION, OBSERVATION_WELL_NUMBER, MINISTRY_OBSERVATION_WELL_STAT,
         WELL_DETAIL_URL) %>%
  collect()

wells_joined <- right_join(wells, wdata_0219,
                          by = c("OBSERVATION_WELL_NUMBER" = "Well_ID"))

library(mapview)

# export the R objects.

if (!dir.exists("tmp")) dir.create("tmp")

save(list = ls(), file = "tmp/welldata.RData")

bc <- bcmaps::bc_bound()

# Create regions based on voronoi tessalation around well locations, grouped by
# 'Region' attribute and merged
wells_regions <- st_union(wells_joined) %>%
  st_voronoi() %>%
  st_sf() %>%
  st_collection_extract("POLYGON") %>%
  st_join(wells_joined[, "Region"]) %>%
  group_by(Region) %>%
  summarise() %>%
  st_intersection(bc) %>%
  mutate()

mapview(wells_regions, zcol = "Region") + mapview(wells_joined, zcol = "Region")
