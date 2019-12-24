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
library(sf)
library(mapview)


wfile <- file.path("process-groundwater-reporting-data/data",
                   "MASTER_Metrics for Publicly Available PGOWN Validated Data.xlsx")

#wfile <- file.path(
#  soe_path("Operations ORCS/Special Projects/Water Program/Groundwater Wells Reporting/Data"),
#  "MASTER_Metrics for Publicly Available PGOWN Validated Data.xlsx"
#)

# Read in the data from Excel sheet using feb 2019 as base

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

# create a well_key for each time slice

well_key <- wdata_0219 %>%
  select(Region, Well_ID, Location)

# write functions to format datasets

get_well_data_graded = function(sheet, range, report_date) {
  tdata <- read_excel(wfile, sheet = sheet, range = range,
         col_names = c("Data_graded", "Well_ID", "Location",
                "Date_Validated", "Months_since_val", "foo","initial_cost","foo1", "comment"),
          col_types = c("text", "text","text", "date", "text",
                "text", "text", "text","text")) %>%
    select(c(Data_graded, Well_ID, Location, Date_Validated,
                     initial_cost, comment))%>%
    filter(!is.na(Well_ID)) %>%
    mutate(initial_cost = as.numeric(initial_cost),
           Well_ID = as.integer(gsub("^#", "", Well_ID))) %>%
    filter_at(.vars = vars(Data_graded, Well_ID), .vars_predicate = any_vars(!is.na(.))) %>%
    mutate(report_data = report_date,
           dateCheck = round(interval(ymd(Date_Validated),
                                      ymd(report_date))/ months(1), 0)) %>%
    left_join(well_key)
}

wdata_0718 <- get_well_data_graded(sheet = "July 2018", range = "B2:J219", report_date = "2018-07-01")
wdata_0719 <- get_well_data_graded(sheet = "July 2019 ", range = "E2:M236", report_date = "2019-07-01")

wdata <- bind_rows(wdata_0219, wdata_0718, wdata_0719)


get_well_data = function(sheet, range, report_date) {
  tdata <- read_excel(wfile, sheet = sheet, range = range,
                      col_names = c( "Well_ID", "Location",
                                    "Date_Validated", "Months_since_val", "foo","initial_cost","foo1", "comment"),
                      col_types = c("text","text", "date", "text",
                                    "text", "text", "text","text")) %>%
    select(c(Well_ID, Location, Date_Validated,
             initial_cost, comment))%>%
    filter(!is.na(Well_ID)) %>%
    mutate(initial_cost = as.numeric(initial_cost),
           Well_ID = as.integer(gsub("^#", "", Well_ID))) %>%
    filter_at(.vars = vars(Well_ID), .vars_predicate = any_vars(!is.na(.))) %>%
    mutate(report_data = report_date,
           dateCheck = round(interval(ymd(Date_Validated),
                                      ymd(report_date))/ months(1), 0)) %>%
    left_join(well_key)
}


wdata_0218 <- get_well_data("Feb 2018", "B2:I214", "2018-02-01" )
wdata_0717 <- get_well_data("July 2017", "B2:I207", "2017-07-01" )
wdata_0217 <- get_well_data("Feb 2017", "B2:I198", "2017-02-01" )
wdata_0716 <- get_well_data("July 2016", "B2:I192", "2016-07-01" )
wdata_0316 <- get_well_data("March 2016", "B2:I193", "2016-03-01" )

# remove 2015 datasets
#wdata_0715 <- get_well_data("July 2015", "B2:I193", "2015-07-01" )
#wdata_0215 <- get_well_data("Feb 2015", "B2:I168", "2015-02-01" )


wdata <- bind_rows(wdata, wdata_0218, wdata_0717,wdata_0217,
                   wdata_0716, wdata_0316)

rm(wdata_0219, wdata_0218, wdata_0717,wdata_0217,
   wdata_0716, wdata_0316,wdata_0719,wdata_0718 )

# update missing "region" values

region_table <- tribble(
  ~ Location, ~ Region2,
  "Merrit", "Cariboo/Thompson",
  "Joe Rich", "Okanagan/Kootenay",
  "Pemberton", "Lower Mainland",
  "Deroche", "Lower Mainland",
  "Dewdney", "Lower Mainland",
  "NG-Charlie Lake", "Ominca/Peace",
  "Canoe Creek", "Cariboo/Thompson",
  "Farmington", "Ominca/Peace",
  "Junction Sheep", "Cariboo/Thompson",
  "Shuswamp Lake Park Deep", "Cariboo/Thompson",
  "Salmon Arm", "Cariboo/Thompson",
  "Ellison", "Okanagan/Kootenay"
)

wdata <- wdata %>%
  left_join(region_table) %>%
  mutate(Region = ifelse(is.na(Region), Region2, Region)) %>%
  select(- Region2) %>%
  group_by(Location) %>%
  mutate(Region = ifelse(is.na(Region), first(Region), Region )) %>%
  ungroup() %>%
  mutate(inactive = ifelse(is.na(Date_Validated), "Y","N"))

# data checks
#inactive <- wdata %>% filter(inactive == "Y")
#with.region <- wdata %>% filter(!is.na(Region))
#no.region <- wdata %>% filter(is.na(Region))



# import well dataset from the data catalogue ( )

# get wells column names
bcdc_describe_feature("e4731a85-ffca-4112-8caf-cb0a96905778")

# Get the wells which have an OBSERVATION_WELL_NUMBER (and thus are part of PGOWN)
wells <- bcdc_query_geodata("e4731a85-ffca-4112-8caf-cb0a96905778") %>%
  filter(!is.na(OBSERVATION_WELL_NUMBER)) %>%
  select(WELL_LOCATION, OBSERVATION_WELL_NUMBER, MINISTRY_OBSERVATION_WELL_STAT,
         WELL_DETAIL_URL) %>%
  collect()


wells_joined <- right_join(wells, wdata ,
                          by = c("OBSERVATION_WELL_NUMBER" = "Well_ID"))


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

mapview(wells_regions, zcol = "Region") +
  mapview(wells_joined, zcol = "Region", legend = FALSE)


# export the R objects.

if (!dir.exists("tmp")) dir.create("tmp")
save(list = ls(), file = "tmp/welldata.RData")

