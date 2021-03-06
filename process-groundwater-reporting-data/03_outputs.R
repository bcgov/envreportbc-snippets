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

library(ggplot2)
library(dplyr)
library(gridExtra)
library(patchwork)

dir.create("process-groundwater-reporting-data/output/plots", recursive = TRUE, showWarnings = FALSE)

# Create and overall plot

x <- well.stats %>%
  filter(is.na(Region))

# plot with % wells validated
ggplot(well.stats, aes(report_data, 100 - pc.gth.7,color = Region, fill = Region, shape = Region)) +
  geom_point() + geom_line()+
  ylim(0,100) +
  labs(title = "% Wells validated within 7 months",
       x = "", y = "Percentage of active wells")

# amount of time since validates

ggplot(well.stats, aes(report_data, mth.ave, color = Region, fill = Region, shape = Region)) +
 geom_pointrange(aes(ymin = mth.ave - mth.sd , ymax = mth.ave + mth.sd )) +
  geom_line() +
  coord_cartesian(ylim = c(0,100))


ggplot(well.stats, aes(report_data, mth.ave, color = Region, fill = Region, shape = Region)) +
  facet_wrap(~Region, scales = "free")+
  geom_pointrange(aes(ymin = mth.ave - mth.sd , ymax = mth.ave + mth.sd )) +
  geom_line() +
  #geom_text(aes(label=no.active.wells), vjust = -1) +
  theme(legend.position = "none")



# Create Popup plots for report ------------------------------------------


# Regional Plots  ---------------------------------------------------------

# Create list of GBPU
reg_list <- unique(well.stats$Region)

# Create list for plots
reg_plot_list <- vector(length = length(reg_list), mode = "list")
names(reg_plot_list) <- reg_list

# Create plotting function for regions

temp_plots <- function(reg.data) {
  p1 <- ggplot(reg.data, aes(report_data, 100 - pc.gth.7)) +
    geom_bar(stat = "identity") +
    ylim(0,100) +
    geom_text(aes(label=no.active.wells), vjust = -1) +
    labs(title = "% Wells validated within 7 months",
         x = "", y = "Percentage of active wells")

  p2 <-ggplot(reg.data, aes(report_data, mth.ave)) +
    geom_bar(stat = "identity") +
    geom_text(aes(label= round(mth.ave, 0), vjust = -1))+
    ylim(0, max(reg.data$mth.ave + 0.1* max(reg.data$mth.ave))) +
    labs(title = "Average time since validation ",
         x = "", y = "No. of months") +
    geom_hline(yintercept=7, linetype="dashed", color = "red")

  p1 / p2
}


ggplot(well.stats, aes(report_data, mth.ave, color = Region, fill = Region, shape = Region)) +
  facet_wrap(~Region, scales = "free")+
  geom_pointrange(aes(ymin = mth.ave - mth.sd , ymax = mth.ave + mth.sd )) +
  geom_line() +
  #geom_text(aes(label=no.active.wells), vjust = -1) +
  theme(legend.position = "none")





# Create ggplot graph loop
plots <- for (n in reg_list) {
  print(n)
  reg.data <- well.stats %>% filter(Region == n)
  p <- temp_plots(reg.data)
  #name = gsub("/","_",n )
  ggsave(p, file = paste0("process-groundwater-reporting-data/output/plots/",n, ".svg"))
  reg_plot_list [[n]] <- p
}


## Plot 2 : create overall summary with all data and years.

p1 <- ggplot(well.table, aes(report_data, 100 - pc.gth.7)) +
  geom_bar(stat = "identity") +
  ylim(0,100) +
  geom_text(aes(label=no.active.wells), vjust = -1) +
  labs(title = "% Wells validated within 7 months",
       x = "", y = "Percentage of active wells")

p2 <-ggplot(well.table,  aes(report_data, mth.ave)) +
  geom_bar(stat = "identity") +
  geom_text(aes(label= round(mth.ave, 0), vjust = -1))+
  ylim(0, max(well.table$mth.ave + 0.1* max(well.table$mth.ave))) +
  labs(title = "Average time since validation ",
       x = "", y = "No. of months") +
  geom_hline(yintercept=7, linetype="dashed", color = "red")


# Indiviual plots per well ---------------------------------------------------------
#
# # Create list of wells
# wells_list <- unique(well.detailed$well.name)
#
# # Create list for plots
# wells_plot_list <- vector(length = length(wells_list), mode = "list")
# names(wells_plot_list) <- wells_list
#
#
# indiv_plots <- function(wellid.data) {
#   p2 <-ggplot(wellid.data, aes(report_data, dateCheck)) +
#     geom_bar(stat = "identity") +
#     #geom_text(aes(label= round(mth.ave, 0), vjust = -1))+
#     ylim(0, max(wellid.data$dateCheck + 0.1* max(wellid.data$dateCheck))) +
#     labs(title = paste0( "Validation history : ", wellid.data$Location, " (#", wellid.data$OBSERVATION_WELL_NUMBER, ")"),
#          x = "", y = "Months") +
#     geom_hline(yintercept=7, linetype="dashed", color = "red")
# }
#
#
# # Create ggplot graph loop
# plots <- for (w in wells_list) {
#  # w = wells_list[1]
#   print(w)
#   wellid.data <- well.detailed %>% filter(well.name == w) %>%
#     select(c(OBSERVATION_WELL_NUMBER, Region, Location, Date_Validated,  Months_since_val, initial_cost, comment,
#            report_data, inactive, dateCheck, well.name))
#
#   p <- indiv_plots(wellid.data)
#
#   ggsave(p, file = paste0("process-groundwater-reporting-data/output/plots/",w, ".svg"))
#   wells_plot_list [[w]] <- p
# }

saveRDS(reg_plot_list, "process-groundwater-reporting-data/reg_plot_list.rds")
saveRDS(wells_plot_list, "process-groundwater-reporting-data/wells_plot_list.rds")

