library(readr) #load data from BC Data Catalogue
library(readxl) #load xlsx files
library(dplyr) # data munging
library(dataCompareR)

source("R/functions.R")

cpa <- read_csv("process-bcsee-data/out/BCSEE_Plants_Animals.csv",
                col_types = cols(`Global Status Review Date` = col_date(format = ""),
                                 `Prov Status Review Date` = col_date(format = ""),
                                 `Prov Status Change Date` = col_date(format = ""),
                                 .default = col_character()))

pre11_files <- list.files("process-bcsee-data/data/",
                          pattern = "^20((0[1-9])|10).+\\.(xlsx?|csv)$",
                          full.names = TRUE)

names(pre11_files) <- gsub(".+?([0-9]{4})([a-zA-Z]{1,12})?.+", "\\L\\2_\\1",
                           pre11_files, perl = TRUE)

lapply(pre11_files, function(f) {
  name <- names(pre11_files)[pre11_files == f]
  d <- if (grepl("csv$", f)) {
    readr::read_csv(f, col_types = cols(.default = col_character()))%>%
      mutate_at(vars(ends_with("Date")), to_date_from_excel)
  } else {
    readxl::read_excel(f, col_types = "text") %>%
      mutate_at(vars(ends_with("Date")), to_date_from_excel)
  }
  assign(name, d, envir = .GlobalEnv)
})

yrs <- as.integer(unique(gsub("?.+([0-9]{4})", "\\1", names(pre11_files))))

name_mapping <- list(
  y2004 = c("Subgroup" = "Name Category",
           "Taxonomic Group" = "Name Category",
           "Identified Wildlife" = "Provincial FRPA",
           "G Rank" = "Global Status",
           "Provinicial" = "Prov Status", # Typo is real
           "BC Status" = "BC List"),
  y2005 = c("RISC Code" = "Species Code",
           "Global Rank" = "Global Status",
           "Prov Rank" = "Prov Status",
           "BC Status" = "BC List",
           "Identified Wildlife" = "Provincial FRPA",
           "CDC Track" = "Mapping Status",
           "National GS" = "General Status Canada",
           "Habitat Type" = "Habitat Subtype",
           "Exotic" = "Origin",
           "Accidental" = "Presence",
           "Taxonomic Group" = "Name Category"),
  y2006 = c("RISC Code" = "Species Code",
           "Global Rank" = "Global Status",
           "Prov Rank" = "Prov Status",
           "BC Status" = "BC List",
           "Identified Wildlife" = "Provincial FRPA",
           "CDC Track" = "Mapping Status",
           "National GS" = "General Status Canada",
           "Habitat Type" = "Habitat Subtype",
           "Exotic" = "Origin",
           "Accidental" = "Presence",
           "Prov Rank Review Date" = "Prov Status Review Date",
           "Prov Rank Change Date" = "Prov Status Change Date"),
  y2007 = c("RISC Code" = "Species Code",
           "Global Rank" = "Global Status",
           "Prov Rank" = "Prov Status",
           "BC Status" = "BC List",
           "Identified Wildlife" = "Provincial FRPA",
           "CDC Track" = "Mapping Status",
           "National GS" = "General Status Canada",
           "Habitat Type" = "Habitat Subtype",
           "Exotic" = "Origin",
           "Accidental" = "Presence",
           "Prov Rank Review Date" = "Prov Status Review Date",
           "Prov Rank Change Date" = "Prov Status Change Date"),
  y2008 = c("RISC Code" = "Species Code",
           "Global Rank" = "Global Status",
           "Prov Rank" = "Prov Status",
           "BC Status" = "BC List",
           "Identified Wildlife" = "Provincial FRPA",
           "CDC Track" = "Mapping Status",
           "National GS" = "General Status Canada",
           "Habitat Type" = "Habitat Subtype",
           "Exotic" = "Origin",
           "Accidental" = "Presence",
           "Prov Rank Review Date" = "Prov Status Review Date",
           "Prov Rank Change Date" = "Prov Status Change Date"),
  y2009 = c("RISC Code" = "Species Code",
           "Identified Wildlife" = "Provincial FRPA",
           "National GS" = "General Status Canada",
           "Habitat Type" = "Habitat Subtype",
           "Action Groups" = "CF Action Groups",
           "Highest Priority" = "CF Highest Priority",
           "Priority Goal 1" = "CF Priority Goal 1",
           "Priority Goal 2" = "CF Priority Goal 2",
           "Priority Goal 3" = "CF Priority Goal 3")
)

for (y in yrs) {
  aname <- paste0("animals_", y)
  pname <- paste0("plants_", y)
  if (exists(aname) && exists(pname)) {
    a <- get(aname, envir = .GlobalEnv)
    p <- get(pname, envir = .GlobalEnv)
    rename_vec <- name_mapping[[paste0("y", y)]]
    names(a)[names(a) %in% names(rename_vec)] <- na.omit(rename_vec[names(a)])
    names(p)[names(p) %in% names(rename_vec)] <- na.omit(rename_vec[names(p)])
    d <- bind_rows(a, p)
    name_diffs <- setdiff(names(d), names(cpa))
    print(name_diffs)
    if (!length(name_diffs)) {
      assign(paste0("plants_animals_", y), d, envir = .GlobalEnv)
      rm(list = c(aname, pname, "a", "p", "d"), envir = .GlobalEnv)
    }
  }
}
