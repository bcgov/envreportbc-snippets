#!/bin/sh

# Copyright 2016 Province of British Columbia
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

## You may need to set this - Point it to where your personal R library is
# set R_LIBS="C:/R/win_library"

################################################
#                                              #
#                    Testing                   #
#                                              #
################################################

## Pipe in head and don't specify an output file to test it. This is recommended!

head C--O_1998_2015.csv | Rscript cleanair.R --co --2015
head H2-S_1998_2015.csv | Rscript cleanair.R --h2s --2015
head N--O_1998_2015.csv | Rscript cleanair.R --no --2015
head NO-2_1998_2015.csv | Rscript cleanair.R --no2 --2015
head SO-2_1998_2015.csv | Rscript cleanair.R --so2 --2015
head OZNE_1998_2015.csv | Rscript cleanair.R --o3 --2015
head PM10_1994_2015.csv | Rscript cleanair.R --pm10 --2015
head PM25_integrated.csv | Rscript cleanair.R --pm25 --2015

################################################
#                                              #
#                The real thing                #
#                                              #
################################################

## Uncomment and edit the script below when your test works. Please note, it as advised
## to copy this script and cleanair.R as well as all of the data files to a directory
## On your C:/ drive and run it there.

## Create an output folder
# mkdir cleaned

## Run cleanair.R on each raw file and output to a new file in the "cleaned" directory:
# Rscript cleanair.R --co --2015 C--O_1998_2015.csv > cleaned/CO_hourly.csv
# Rscript cleanair.R --h2s --2015 H2-S_1998_2015.csv > cleaned/H2S_hourly.csv
# Rscript cleanair.R --no --2015 N--O_1998_2015.csv > cleaned/NO_hourly.csv
# Rscript cleanair.R --no2 --2015 NO-2_1998_2015.csv > cleaned/NO2_hourly.csv
# Rscript cleanair.R --o3 --2015 OZNE_1998_2015.csv > cleaned/O3_hourly.csv
# Rscript cleanair.R --so2 --2015 SO-2_1998_2015.csv > cleaned/SO2_hourly.csv
# Rscript cleanair.R --pm10 --2015 PM10_1994_2015.csv > cleaned/PM10_hourly.csv
# Rscript cleanair.R --pm25 --2015 PM25_integrated.csv > cleaned/PM25_hourly.csv

## Make a 200-row head of each file, and make a zip of each large file
# cd cleaned
# for file in *hourly.csv; do zip -r ${file%.csv}.zip $file; done
# mkdir sample_200
# for file in *.csv; do head -n200 $file > sample_200/sample_$file; done
