# Clean Hourly Air Quality Data

Process hourly air quality data exported from Envista to format for DataBC record: 
https://catalogue.data.gov.bc.ca/dataset/air-quality-monitoring-verified-hourly-data-and-station-data

The raw data files look like this:

```
E231866,Victoria Topaz                               ,C--O,  1,  01MAY1998:01:00:00,1998,05 ,2 ,1 ,0 ,0 ,0 ,
E231866,Victoria Topaz                               ,C--O,  1,  01MAY1998:02:00:00,1998,05 ,2 ,1 ,0 ,0 ,0 ,
E231866,Victoria Topaz                               ,C--O,  1,  01MAY1998:03:00:00,1998,05 ,1 ,1 ,0 ,0 ,0 ,
E231866,Victoria Topaz                               ,C--O,  1,  01MAY1998:04:00:00,1998,05 ,0 ,1 ,0 ,0 ,0 ,
E231866,Victoria Topaz                               ,C--O,  1,  01MAY1998:05:00:00,1998,05 ,1 ,1 ,0 ,0 ,0 ,
```

Or, in the case of PM2.5, like this:

```
M107004,Houston Firehall_60                          ,PM25      ,PM25      ,PM25_R&P_TEOM   ,  6,  26JUL2001:10:00:00,2001,07 ,3 ,1 ,0 ,0 ,0 ,
M107004,Houston Firehall_60                          ,PM25      ,PM25      ,PM25_R&P_TEOM   ,  6,  26JUL2001:11:00:00,2001,07 ,3 ,1 ,0 ,0 ,0 ,
M107004,Houston Firehall_60                          ,PM25      ,PM25      ,PM25_R&P_TEOM   ,  6,  26JUL2001:12:00:00,2001,07 ,5 ,1 ,0 ,0 ,0 ,
M107004,Houston Firehall_60                          ,PM25      ,PM25      ,PM25_R&P_TEOM   ,  6,  26JUL2001:13:00:00,2001,07 ,7 ,1 ,0 ,0 ,0 ,
M107004,Houston Firehall_60                          ,PM25      ,PM25      ,PM25_R&P_TEOM   ,  6,  26JUL2001:14:00:00,2001,07 ,5 ,1 ,0 ,0 ,0 ,
```

This script cleans them up by:

- Reformatting dates to ISO8061 standard (`YYYY-MM-DD HH:MM:SS`)
- Removing extra white space
- Removing trailing commas
- Providing column names
- Removing extraneous columns

There are two files: `cleanair.R` and `cleanair.sh`:

- `cleanair.R` is an R script designed to be run from the command line, that processes the raw air files. 
  Get help on how to use it by running `Rscript cleanair.R --help`.
- `cleanair.sh` is a short shell script that runs `cleanair.R` on each of the raw data files.

## Running the script:

- It is advised to copy all of the raw data files as well as the two `cleanair.*` script files to a directory on your `C:/` drive - it is very slow running on a network drive.
- Make sure that `cleanair.sh`, `cleanair.R`, and the raw data files are all in the same directory.
- Edit `cleanair.sh` to define the year you are preparing the data for, and define the file names and folder paths accordingly.
- The `cleanir.sh` script has a section to test it, and a section to run it on the full files. It is recommended to test it first as the real operation takes a while.
- Run `cleanair.sh` from the terminal window with: `sh cleanair.sh`

### License

    Copyright 2016 Province of British Columbia

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at 

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
