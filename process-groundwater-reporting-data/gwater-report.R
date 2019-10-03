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


wfile <- file.path(
  soe_path("Operations ORCS/Special Projects/Water Program/Groundwater Wells Reporting/Data"),
           "MASTER_Metrics for Publicly Available PGOWN Validated Data.xlsx"
)


wdata <- read_excel(wfile, sheet = "Feb 2019", range = "A2:J228",
                  col_names = c("Region", "Data_graded", "Well_ID", "Location",
                          "Date_Validated", "Months_since_val", "foo","initial_cost","foo1", "comment"),
                  col_types = c("text", "text", "text","text", "date", "text",
                                "text", "text", "text","text")) %>%
                select(-c("foo", "foo1")) %>%

wdata <- wdata %>%
  mutate(Region = ifelse(str_detect(Region, "%"),"NA",Region),
         Region = ifelse(str_detect(Region, "Total"),"NA",Region))

                         ifelse(str_detect(Region, "Total", "NA"),Region)))

  mutate(test = str_detect(measure_long,"Population|Per Person")) %>%
           filter(test == "FALSE")


wdata <- wdata %>%
  fill(Region)



fill(data, ..., .direction = c("down", "up", "downup", "updown"))

