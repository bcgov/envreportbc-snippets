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

to_date_from_excel <- function(x, version = c("win_new_mac", "mac_08")) {

  if (all(grepl("^[0-9]{4,6}(\\.[0-9]{1,3})?", na.omit(x)))) {
    # Excel dates are formatted as number of days since Jan 1, 1900. However,
    # Excel thinks 1900 was a leap year (it wasn't) and Excel treats the origin
    # as Day 1, while R treats the origin as Day 0. So need to subtract two days.
    # Unless you are using Excel for Mac 2008 or earlier, in which case the origin
    # is 1904-01-01 and that is Day 0
    version = match.arg(version)

    origin = switch(version,
                    win_new_mac = as.Date("1900-01-01") - 2,
                    mac_08 = as.Date("1904-01-01"))


    return(as.Date(as.numeric(x), origin = origin))
  }

  if (!requireNamespace("lubridate", quietly = TRUE)) {
    stop("Package lubridate required", call. = FALSE)
  }

  date_format <- lubridate::guess_formats(na.omit(x),
                                          orders = c("BdY", "dBy", "dby", "mdY", "Bdy", "bdY", "bdy"))[1]

  as.Date(x, format = date_format)
}

