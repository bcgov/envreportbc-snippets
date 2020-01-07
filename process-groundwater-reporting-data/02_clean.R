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


if (!exists("wells_regions")) load("tmp/welldata.RData")


wells.df <- data.frame(wells_joined)
wells.df <- wells.df %>%
  mutate( Region = gsub("/","_", Region))


well.detailed <- wells_joined %>%
  select(c(OBSERVATION_WELL_NUMBER, WHEN_CREATED,
           WELL_DETAIL_URL, geometry, Region, Location, Date_Validated, Months_since_val,
           initial_cost, comment, report_data , dateCheck,inactive)) %>%
  mutate(well.name = paste0("w_", OBSERVATION_WELL_NUMBER),
         report_data = ymd(report_data))


# finacial start up cost
well.cost <- wells.df %>%
  group_by(Region, report_data) %>%
  summarise(invest_cost = sum(initial_cost, na.rm = TRUE))


# number of wells per regions over time.
well.stats  <- wells.df %>%
  group_by(Region, report_data) %>%
  filter(!inactive == "Y") %>%
  summarise(no.active.wells = length(unique(WELL_ID)),
            no.gth.7 = round(sum(dateCheck > 7, na.rm = TRUE), 1),
            mth.ave = round(mean(dateCheck, na.rm = TRUE), 1),
            mth.total = round(sum(dateCheck, na.rm = TRUE), 1),
            no.grad = round(sum(as.numeric(graded), na.rm = TRUE))) %>%
  mutate(pc.gth.7 = round(no.gth.7 / no.active.wells * 100, 1),
         pc.grad = round(no.grad / no.active.wells * 100, 1),
         report_data = ymd(report_data)) %>%
  ungroup()


well.stats$Region = factor(well.stats$Region, ordered = TRUE,
                           levels = c("Skeena", "Ominca_Peace", "Okanagan_Kootenay","Cariboo_Thompson",
                                      "Lower Mainland",  "Vancouver Island"))

# format table - most recent year
well.table.recent <- well.stats %>%
  filter(report_data == max(report_data)) %>%
  select(c(Region, report_data, no.active.wells, no.gth.7, pc.gth.7, mth.ave, no.grad, pc.grad ))


reporting_date = max(well.stats$report_data)

# format table - all years
well.table <- well.stats %>%
  select(c(report_data, no.active.wells, no.gth.7, pc.gth.7, mth.ave, no.grad, pc.grad )) %>%
  group_by(report_data) %>%
  summarise(no.active.wells = sum(no.active.wells),
            no.gth.7 = round(sum(no.gth.7), 1),
            mth.ave = round(mean(mth.ave, na.rm = TRUE), 1),
            pc.grad = round(mean(pc.grad, na.rm = TRUE), 0)) %>%
  mutate(pc.gth.7 = round(no.gth.7/no.active.wells*100, 0))

#save(well.table, file = "process-groundwater-reporting-data/tmp/well.table.rds")

save(list = ls(), file = "process-groundwater-reporting-data/tmp/wellsum.RData")
