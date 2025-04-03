# Amanda Batlle Morera (a.batll@creaf.uab.cat)
# Code to implement in AquaGalaxy.

# AquaINFRA Mediterranean Case Use: 
# Step 2 Mediterranean inland to marine model connection: 

# Tool Name: SWAT+ output to MITGCM input connection tool.
#
# Description: 
#   This code converts SWAT output of water quantity (Flow out and Temperature) in csv format to date input for MITGCM in txt format. 
#
# Inputs: 
#   id: flow_file
#   Title: Daily river flow out
#   Data Type: string
#   Description: csv file containing daily flow out values (units: m3/s). 
# 
#   id: temp_file
#   Title: Daily river water temperature
#   Data Type: string
#   Description: csv file containing daily water temperature values (units: Degrees Celsius).
#
# Output :
#   id: output_file
#   Title : River water quantity MITGCM input
#   Description: txt file (MITGCMinput_RiverWaterQuantityFromSWAT.txt) containing a data frame with the correct formatting and structure to enter MITGCM model. 

Conversion_SWAT_MITGCM_WaterQuantity <- function( flow_file, temp_file, output_file = "MITGCMinput_RiverWaterQuantityFromSWAT.txt"){
  # List required packages
  requiredPackages <- c("readr", "dplyr", "lubridate")
  
  # Install missing packages before running the function
  missingPackages <- setdiff(requiredPackages, rownames(installed.packages()))
  if (length(missingPackages) > 0) install.packages(missingPackages, dependencies = TRUE)
  
  # Load packages quietly
  suppressPackageStartupMessages(lapply(requiredPackages, library, character.only = TRUE))
  
  # Read and process water flow data
  df_flowout <- read_delim(flow_file, delim = ",", show_col_types = FALSE) %>%
    select(Date, Value) %>%
    rename(date = Date, flowout = Value) %>%
    mutate(date = dmy(date),  # Use lubridate for better date parsing
           flowout = as.numeric(flowout))  # Ensure numeric type
  
  # Read and process water temperature data
  df_temp <- read_delim(temp_file, delim = ",", show_col_types = FALSE) %>%
    select(date, tmp_interpol) %>%
    mutate(date = ymd(date))  # Ensure consistent date format
  
  # Merge datasets
  df <- df_flowout %>%
    left_join(df_temp, by = "date") %>%
    mutate(time = "12:00:00",
           date = format(date, "%Y%m%d"),
           output_data = paste0(date, "-", time, " ", flowout, " ", tmp_interpol))
  
  # Export to text file
  write.table(df$output_data, file = output_file, row.names = FALSE, col.names = FALSE, quote = FALSE)
  
  message("File successfully written: ", output_file)
}
