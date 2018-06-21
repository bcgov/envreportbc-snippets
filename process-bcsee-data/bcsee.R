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

# Load libraries
library(readr)
library(dplyr)

## Load historical datset from the BC Data Catalogue, distrubuted udner the
## Open Government Licence - British Columbia:
## https://catalogue.data.gov.bc.ca/dataset/d3651b8c-f560-48f7-a34e-26b0afc77d84

bcsee_plants_animals <- read_csv("https://catalogue.data.gov.bc.ca/dataset/d3651b8c-f560-48f7-a34e-26b0afc77d84/resource/39aa3eb8-da10-49c5-8230-a3b5fd0006a9/download/bcseeplantsanimals.csv")

bcsee_communities <- read_csv("https://catalogue.data.gov.bc.ca/dataset/d3651b8c-f560-48f7-a34e-26b0afc77d84/resource/bbacd6fb-6708-4cf8-b353-0dc5ef75b7b9/download/bcseecommunities.csv")
