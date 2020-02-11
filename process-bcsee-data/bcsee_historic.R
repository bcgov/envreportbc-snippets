library(readr) #load data from BC Data Catalogue
library(readxl) #load xlsx files
library(dplyr) # data munging
library(dataCompareR)

source("R/functions.R")

current_pa <- read_csv("process-bcsee-data/out/BCSEE_Plants_Animals.csv",
                       col_types = cols(`Global Status Review Date` = col_date(format = ""),
                                        `Prov Status Review Date` = col_date(format = ""),
                                        `Prov Status Change Date` = col_date(format = ""),
                                        .default = col_character()))

current_c <- read_csv("process-bcsee-data/out/BCSEE_Communities.csv",
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

pa_name_mapping <- list(
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

c_name_mapping <- list(
  y2004 = c("Identified Wildlife" = "Provincial FRPA",
            "G Rank" = "Global Status",
            "Provinicial" = "Prov Status", # Typo is real
            "BC Status" = "BC List"),
  y2005 = c("Global Rank" = "Global Status",
            "Prov Rank" = "Prov Status",
            "BC Status" = "BC List",
            "Identified Wildlife" = "Provincial FRPA",
            "CDC Track" = "Mapping Status"),
  y2006 = c("Global Rank" = "Global Status",
            "Prov Rank" = "Prov Status",
            "BC Status" = "BC List",
            "Identified Wildlife" = "Provincial FRPA",
            "Forest District" = "Forest Dist",
            "CDC Track" = "Mapping Status",
            "Prov Rank Review Date" = "Prov Status Review Date",
            "Prov Rank Change Date" = "Prov Status Change Date"),
  y2007 = c("Global Rank" = "Global Status",
            "Prov Rank" = "Prov Status",
            "BC Status" = "BC List",
            "Identified Wildlife" = "Provincial FRPA",
            "Forest District" = "Forest Dist",
            "CDC Track" = "Mapping Status",
            "Prov Rank Review Date" = "Prov Status Review Date",
            "Prov Rank Change Date" = "Prov Status Change Date"),
  y2008 = c("Global Rank" = "Global Status",
            "Prov Rank" = "Prov Status",
            "BC Status" = "BC List",
            "Identified Wildlife" = "Provincial FRPA",
            "Forest District" = "Forest Dist",
            "CDC Track" = "Mapping Status",
            "Prov Rank Review Date" = "Prov Status Review Date",
            "Prov Rank Change Date" = "Prov Status Change Date"),
  y2009 = c("Identified Wildlife" = "Provincial FRPA",
            "Biogeoclimatic Units" = "BGC",
            "Forest District" = "Forest Dist",
            "Action Groups" = "CF Action Groups",
            "Highest Priority" = "CF Highest Priority",
            "Priority Goal 1" = "CF Priority Goal 1",
            "Priority Goal 2" = "CF Priority Goal 2",
            "Priority Goal 3" = "CF Priority Goal 3")
)



for (y in setdiff(yrs, 2010)) {
  aname <- paste0("animals_", y)
  pname <- paste0("plants_", y)
  cname <- paste0("communities_", y)
  a <- get(aname, envir = .GlobalEnv)
  p <- get(pname, envir = .GlobalEnv)
  c <- get(cname, envir = .GlobalEnv)
  rename_vec_pa <- pa_name_mapping[[paste0("y", y)]]
  names(a)[names(a) %in% names(rename_vec_pa)] <- na.omit(rename_vec_pa[names(a)])
  names(p)[names(p) %in% names(rename_vec_pa)] <- na.omit(rename_vec_pa[names(p)])
  d <- bind_rows(a, p)
  d$Year <- as.character(y)
  rename_vec_c <- c_name_mapping[[paste0("y", y)]]
  names(c)[names(c) %in% names(rename_vec_c)] <- na.omit(rename_vec_c[names(c)])
  c$Year <- as.character(y)
  name_diffs_pa <- setdiff(names(d), names(current_pa))
  print(name_diffs_pa)
  name_diffs_c <- setdiff(names(c), names(current_c))
  if (!length(name_diffs_pa)) {
    assign(paste0("plants_animals_", y), d, envir = .GlobalEnv)
  }
  if (!length(name_diffs_c)) {
    assign(paste0("communities_new_", y), c, envir = .GlobalEnv)
  }
}

# Process the combined plants & animals + communities for 2010

exotic_lookup <- c(
  "1" = "Native",
  "2" = "Exotic",
  "3" = "Unknown/Undetermined"
)

accidental_lookup <- c(
  "1" = "Regularly occurring",
  "2" = "Accidental/Nonregular",
  "3" = "Unknown/Undetermined"
)

gen_status_lookup <- c(
  ".1" = "Extirpated",
  ".2" = "Extinct",
  "1" = "At Risk",
  "2" = "May be at risk",
  "3" = "Sensitive",
  "4" = "Secure",
  "5" = "Undetermined",
  "6" = "Not Assessed",
  "7" = "Exotic",
  "8" = "Accidental"
)

kingdom_lookup <- c(
  "I" = "Animalia",
  "A" = "Animalia",
  "N" = "Plantae",
  "P" = "Plantae"
)

name_mapping_2010 <- c(
  "Year",
  "Element Code" = "ELCODE",
  "Species Level" = "TAXLEVEL",
  "Kingdom",
  "Phylum" = "TAXPHYLUM",
  "Class" = "TAXCLASS",
  "Class (English)" = "CLASS_ENG",
  "Order" = "TAXORDER",
  "Family" = "TAXFAMILY",
  # "NAME_TYPE_CD",
  "Name Category" = "EL_TYPE",
  # "GNAME",
  # "GCOMNAME",
  "Scientific Name" = "SNAME",
  # "FORMAT_SNAME",
  # "SNAME_AUTHOR",
  "English Name" = "SCOMNAME",
  # "FORMAT_SCOMNAME",
  "Global Status" = "GRANK",
  # "G_RANK_CHANGE_DATE",
  "Global Status Review Date" = "G_RANK_REVIEW_DATE",
  "Prov Status" = "SRANK",
  "Prov Status Change Date" = "S_RANK_CHANGE_DATE",
  "Prov Status Review Date" = "S_RANK_REVIEW_DATE",
  "BC List" = "LIST",
  "Presence",
  "Origin",
  "General Status Canada",
  "Provincial FRPA",
  "COSEWIC",
  "COSEWIC Comments" = "COSEWIC_COM",
  # "COSEWIC_CD",
  # "COSEWIC_DATE",
  "CDC Maps" = "CDCTRACK",
  "Endemic" = "ENDEMISM",
  # "BREEDING",
  # "IDENT_WILDLIFE_CD",
  # "IDENT_WILDLIFE_DATE",
  # "IDENT_WILDLIFE_COM",
  # "ACCIDENTAL_ID",
  # "EXOTIC_ID",
  # "ORDER_SEQ_NUM",
  # "FAMILY_SEQ_NUM",
  "Species Code" = "RISC_CODE",
  # "EO_EXISTS",
  "SARA",
  # "SARA_STS",
  # "SARA_DATE",
  "SARA Comments" = "SARA_COM",
  "Prov Wildlife Act" = "WILDLIFE_ACT",
  "MBCA",
  # "NATL_STATUS",
  # "NATL_STATUS_DATE",
  "CF Highest Priority" = "CF_PRIORITY_HIGHEST",
  "CF Priority Goal 1" = "CF_PRIORITY_GOAL1",
  "CF Priority Goal 2" = "CF_PRIORITY_GOAL2",
  "CF Priority Goal 3" = "CF_PRIORITY_GOAL3",
  "CF Action Groups" = "CF_ACTION_GROUPS"
)

biot_2010 <- biot_2010 %>%
  mutate(
    Year = "2010",
    Kingdom = unname(kingdom_lookup[substr(ELCODE, 1, 1)]),
    COSEWIC = ifelse(!is.na(COSEWIC_CD),
                     paste0(COSEWIC_CD, " (", format(COSEWIC_DATE, "%Y"), ")"),
                     NA_character_),
    `Provincial FRPA` = ifelse(!is.na(IDENT_WILDLIFE_CD),
                               paste0(IDENT_WILDLIFE_CD, " (", format(IDENT_WILDLIFE_DATE, "%Y"), ")"),
                               NA_character_),
    SARA = ifelse(!is.na(SARA),
                  paste0(SARA, " (", format(SARA_DATE, "%Y"), ")"),
                  NA_character_),
    Presence = unname(accidental_lookup[ACCIDENTAL_ID]),
    Origin = unname(exotic_lookup[EXOTIC_ID]),
    `General Status Canada` = ifelse(!is.na(NATL_STATUS),
                                     paste0(NATL_STATUS, " - ",
                                            unname(gen_status_lookup[NATL_STATUS]),
                                            " (", format(NATL_STATUS_DATE, "%Y"), ")"),
                                     NA_character_)
  ) %>%
  select(!!!name_mapping_2010)

plants_animals_2010 <- filter(biot_2010, `Name Category` != "Ecological Community") %>%
  select(!!!intersect(names(current_pa), names(.)))

communities_new_2010 <- filter(biot_2010, `Name Category` == "Ecological Community") %>%
  select(!!!intersect(names(current_c), names(.)))

all_c <- bind_rows(mget(c("current_c", ls(pattern = "^communities_new_")))) %>%
  arrange(Year)

all_pa <- bind_rows(mget(c("current_pa", ls(pattern = "^plants_animals_")))) %>%
  arrange(Year)


write_csv(all_c, "process-bcsee-data/out/BCSEE_Communities_final.csv")
write_csv(all_pa, "process-bcsee-data/out/BCSEE_Plants_Animals_final.csv")
