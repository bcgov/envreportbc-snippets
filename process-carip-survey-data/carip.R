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

library(tidyverse)
library(readxl)

## Set survey data year
data_year <- "2017"

## Import the raw data .xlsx file from data/
dir <- "process-carip-survey-data/data"
filename <- paste0(data_year, " CARIP raw data file.xlsx")

## First get the data, without the headers (2 rows)
all_data <- read_xlsx(file.path(dir, filename), col_names = FALSE, skip = 2)

## First row (header) contains the main questions. Use ncol of all_data to get
## the cell range
colnames_1 <- read_xlsx(file.path(dir, filename), col_names = FALSE,
                        range = cell_limits(c(1,1), c(1, ncol(all_data)))) %>%
  unlist()

## Second row contains the sub-questions/descriptions/options. Use ncol of
## all_data to get the cell range
colnames_2 <- read_xlsx(file.path(dir, filename), col_names = FALSE,
                        range = cell_limits(c(2,1), c(2, ncol(all_data)))) %>%
  unlist()

## Drop off the metadata questions (1-5) and create an empty integer column
## to store question numbers
q_labels_df <- bind_cols(question_text = colnames_1, description = colnames_2) %>%
  slice(24:n()) %>%
  mutate(q_num = NA_integer_)

## Hacky loop to parse the data frame of questions and number the questions, starting at
## number 6 and incrementing by one at each non-NA question
format_q <- function(x) paste0("q", formatC(x, width = 4, flag = "0"))

q <- 6
q_labels_df$q_num[1] <- format_q(q)
for (r in seq_len(nrow(q_labels_df))[-1]) {
  if (!is.na(q_labels_df[r, "question_text"])) {
    q <- q + 1
  }
  q_labels_df$q_num[r] <- format_q(q)
}

## Reconstruct the questions and subquestions
q_labels_df <- group_by(q_labels_df, q_num) %>%
  mutate(sub_q = if (n() > 1) formatC(1:n(), width = 4, flag = "0") else NA_character_,
         sub_q = ifelse(description == "Other (please specify)", "other", sub_q),
         question = ifelse(is.na(sub_q), q_num, paste(q_num, sub_q, sep = "_")),
         question_text = ifelse(is.na(question_text), question_text[1], question_text))

## Extract the metadata (respondent information) columns from the full dataset
metadata <- all_data[, 1:23]

## Add metadata column names from headers, replace spaces with underscores
names(metadata) <- c(colnames_1[1:14], colnames_2[15:23])
names(metadata) <- gsub("\\s+", "_", names(metadata))

## Extract the question responses plus the Respondent ID, Local_Govt, and Member_RD columns
data <- select(all_data, 1, 10, 11, X__24:ncol(all_data)) %>%
  set_names(c(names(metadata)[1], "Local_Govt", "Member_RD", q_labels_df$question))

## Gather the wide columns to long format, then join the question data to the responses
data_long <- gather(data, question, response, q0006_0001:q0103) %>%
  left_join(q_labels_df, by = "question") %>%
  mutate(q_num = as.integer(substr(q_num, 2, 5)),
         sub_q = ifelse(sub_q == "other" | is.na(sub_q), 0L, as.integer(sub_q))) %>%
  group_by(Respondent_ID, q_num) %>%
  mutate(
    question_type = case_when(
      grepl("other$", question) ~ "Multiple Choice - 'Other' (free text)",
      n() > 1 & nchar(description) > 1 ~ "Multiple Choice (multi-answer)",
      n() == 1 & description == "Response" ~ "Multiple Choice (single-answer)",
      n() == 1 & description == "Open-Ended Response" ~ "Open-ended (single-answer)",
      n() > 1 & grepl("^[123456789]$", description) & is.integer(sub_q) ~ "Open-ended (multi-answer)",
      TRUE ~ "Aaaargh"
    )
  ) %>%
  select(Respondent_ID, Local_Govt, Member_RD, question, q_num, sub_q, question_type,
         question_text, description, response) %>%
  arrange(Respondent_ID, question)

## Save the re-formatted data as CSV files
write_csv(data_long, (file.path(dir, paste0(data_year, "_survey_monkey_data_long.csv"))))
write_csv(metadata, (file.path(dir, paste0(data_year, "_survey_monkey_metadata.csv"))))


