#!/usr/bin/Rscript

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

suppressMessages(library("lubridate", quietly = TRUE, verbose = FALSE))
suppressMessages(library("readr", quietly = TRUE, verbose = FALSE))

#' clean_envista_data: Process ENVISTA hourly air quality data
#'
#' @param filename: the filename (.csv) exported from envista
#' @param parameter: one of: "O3", "PM10", "PM25", "NO", "NO2", "SO2", "CO", "H2S"
#' @param year: the maximum year you want in the output file (or "all", the default)
#'
#' @return a clean data frame
#'
#' @examples clean_envista_data("C--O_1998_2014.csv", "CO")
clean_envista_data <- function(filename, parameter, year = "all") {
  ## Clear the -- off the parameter name
  parameter <- substr(parameter, 3, nchar(parameter))

  if (!parameter %in% c("O3","PM10","PM25","NO","NO2","SO2","CO","H2S")) {
    stop(parameter, " is not a valid parameter.
Must be one of --O3, --pm25, --pm10, --NO, --NO2, --SO2, --CO, --H2S.
Type 'Rscript cleanair.R --help' for help
")
  }

    # Check that year is valid
  curr_year <- as.integer(format(Sys.Date(), "%Y"))
  if (year != "all") {
    if (!is.numeric(year) || (year > curr_year || year < 1900)) {
      stop("year must be either 'all', or a valid year (as a four digit integer)")
    }
  }

  ## All files have the same structure except for PM2.5
  ## All parameters have units of ppb, except for PM2.5 and PM10 which are in
  ## ug/m3, and CO which is in ppm.

  pm_25_col_names <- c("ems_id", "site", "monitor", "description", "instrument",
                       "v6", "date_time", "year", "month", "value", paste0("v", 11:15))
  pm_25_col_classes <- c(rep("character", 3), "NULL", "character", "NULL",
                         "character", "integer", "NULL", "numeric", rep("NULL",5))

  basic_col_names <- c("ems_id", "site", "parameter", "V4", "date_time", "year",
                       "month", "value", paste0("v", 9:13))

  basic_col_classes <- cols_only(
    ems_id = col_character(),
    site = col_character(),
    parameter = col_character(),
    date_time = col_datetime(format = "%d%b%Y:%H:%M:%S"),
    year = col_integer(),
    month = col_integer(),
    value = col_double()
  )

  pm_25_col_classes <- cols_only(
    ems_id = col_character(),
    site = col_character(),
    monitor = col_character(),
    description = col_character(),
    instrument = col_character(),
    date_time = col_datetime(format = "%d%b%Y:%H:%M:%S"),
    year = col_integer(),
    month = col_integer(),
    value = col_double()
  )

  if (parameter == "PM25") {
    col_names <- pm_25_col_names
    col_classes <- pm_25_col_classes
  } else {
    col_names <- basic_col_names
    col_classes <- basic_col_classes
  }

  data <- read_csv(filename, col_names = col_names,
                   col_types = col_classes, na = c("-88888", "-99999", "-8888", "-9999"))

  ## Truncate the data to only include up to and including the year specified,
  ## but include midnight of Jan 1 the next year
  if (is.integer(year)) {
    ref_date_time <- as.POSIXct(paste0(year + 1, "-01-01T00:00:00"), tz = "UTC")
    data <- data[data$date_time <= ref_date_time, , drop = FALSE]
  }

  ## Check dates:
  m <- lubridate::month(data$date_time)
  y <- lubridate::year(data$date_time)
  if (!all.equal(m, data$month) || !all.equal(y, data$year)) {
    stop("Parsed dates don't match month or year")
  }

  data$date_time <- format(data$date_time)

  ## Some of the raw files have incorrect parameter names in the parameter column.
  ## Check for those and replace if they are wrong.
  if (!exists("parameter", data) || data$parameter[1] != parameter) {
    data$parameter <- parameter
  }

  ## Reorder columns for PM25
  if (parameter == "PM25") data <- data[,c("ems_id", "site", "parameter", "monitor", "instrument", "date_time", "year", "month", "value")]

  ## Create a units column
  if (parameter == "PM25" || parameter == "PM10") {
    data$units <- "ug/m3"
  } else if (parameter == "CO") {
    data$units <- "ppm"
  } else {
    data$units <- "ppb"
  }

  # Remove some crazy negative values
  data$value[data$value < -100000] <- NA

  data
}

helper <- function() {
  cat(
"
This tool transforms the raw hourly data outputs into formats for release on DataBC.
Syntax:

  Rscript cleanair.R [--param] [--year] [filename] > [outputfile]

Param must be one of: --O3, --PM25, --PM10, --NO, --NO2, --SO2, --CO, --H2S
Year is optional, and is used as the maximum year to include. Eg. --2013

It can also read from stdin and it writes to stdout, so you can pipe into it and
omit an output file to test it:

  head OZNE_1998-2013.csv | Rscript cleanair.R --O3

"
)
}

main <- function() {
  ## Capture the command line arguments
  args <- commandArgs(trailingOnly = TRUE)

  ## Parse the first argument to see if it is --help or a parameter
  param <- args[1]
  if (param == "--help") {
    helper()
    return(invisible(NULL))
  }

  ## Parse and pass the year which the cleaned data should include up to
  if (length(args) > 1 && grepl("^--[0-9]{4}$", args[2])) {
    year <- as.integer(substr(args[2], 3, 6))
    args <- args[-2]
  } else {
    year <- "all"
  }

  ## Check to see if there is a filename specified. If there is, use it,
  ## if not use stdin
  filename <- args[-1]
  if (length(filename) == 0) {
    filename <- file("stdin")
  }

  dat <- clean_envista_data(filename, toupper(param), year)
  cat(readr::format_csv(dat))
}

time <- system.time(main())
message("Operation completed in ", time["elapsed"], " s")
