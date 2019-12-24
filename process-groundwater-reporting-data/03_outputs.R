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


#	The change in validated data over time with the presence of a dedicated FTE
#	The change in over time within a region and between regions and as a network as a whole (i.e. it was largely a mess in March 2016 compared to now re: age of data)
#	The number of wells per region, the total # of wells
#	Those regions who exceed the targets
#	Those regions who meet the targets
#	How old the unvalidated data is (the target is no greater than 7 months, some wells are nearing a year, historically some wells were multiple years
#	Because of the # of wells that are reported, the default was to report the average for each region. However, this meant that some wells that were months and months past the target could be masked in an average if the other wells had relatively new data. The response to address this situation was to also report % of wells in a given area that were past the target.
#	You may also have ideas on which colors should be used in the graphics? I simply chose the red/peach combo to highlight which columns to draw attention to. It may be misleading as red often means ‘non compliant’.




# percent of wells validated within the prvious 7 months
# note inverted number

# Create list of GBPU
reg_list <- unique(well.stats$Region)

# Create list for plots
reg_plot_list <- vector(length = length(reg_list), mode = "list")
names(reg_plot_list) <- reg_list


# Create plotting function

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

  grid.arrange(p1, p2, ncol=1)
}


# Create ggplot graph loop
plots <- for (n in reg_list) {
  print(n)
  reg.data <- well.stats %>% filter(Region == n)
  p <- temp_plots(reg.data)
  name = gsub("/","_",n )
  ggsave(p, file = paste0("process-groundwater-reporting-data/output/plots/",name, "_temp.svg"))
  #png_retina(filename = "process-groundwater-reporting-data/output/plots/",name, "_temp.png", width = 400, height = 700,
  #           units = "px", type = "cairo-png", antialias = "default")
  #plot(p)
  #dev.off()
  reg_plot_list [[n]] <- p
}


# create overall summary with all data and years.

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
p2
