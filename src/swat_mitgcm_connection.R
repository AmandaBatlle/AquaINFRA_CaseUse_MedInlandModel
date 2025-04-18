# Amanda Batlle Morera (a.batll@creaf.uab.cat)
# Code to implement in AquaGalaxy.

# AquaINFRA Mediterranean Case Use: 
# Step 2 Mediterranean inland to marine model connection: 

# Tool Name: SWAT+ output to MITgcm input connection tool.
#
# Description: 
#   This code converts SWAT output of water quantity (Flow out and Temperature) in SQL format to data input for MITgcm in txt format. 
#
# Inputs: 
#   "swat_output_file": 
#             "title": "SWAT+ Variable Outputs Database",
#             "description": "SQLite database (thread_1.sqlite) storing the simulated output values based on the defined time range and time step (daily, monthly, yearly, or annual average).",
#             "type": "object",
#             "contentMediaType": "application/sqlite"

# Output :
#   id: output_file
#   Title: River water quantity MITgcm input
#   Description: txt file (MITGCMinput_RiverWaterQuantityFromSWAT.txt) containing a data frame with the correct formatting and structure to enter MITGCM model. 

#install.packages("DBI","RSQLite", "dplyr")
library(DBI)
library(RSQLite)
library(dplyr)

# INPUTS + example values
args <- commandArgs(trailingOnly = TRUE)
print(paste0('R Command line args: ', args))
file1 <- args[1] # thread_1.sqlite
output <- args[2] # /out/MITGCMinput_RiverWaterQuantityFromSWAT.txt

Conversion_SWAT_MITGCM_WaterQuantity <- function( db_path, output_file){
  # Load packages quietly
  suppressPackageStartupMessages(lapply(requiredPackages, library, character.only = TRUE))
  
  # Create a connection to database
  con <- dbConnect(RSQLite::SQLite(), dbname = db_path)
  
  #Connect to DB
  dbListTables(con)
  
  #Read Table
  my_table <- dbReadTable(con, "run_1_1.1")
  
  # Correct date format: 
  my_table$date <- as.Date(my_table$date, origin = "1970-01-01") #Convert date from, Unix Epoch date format (days since 1970-01-01) to YYYY-MM-DD.
  
  df <- my_table %>%
    mutate(flo_out = format(flo_out, digits = 6, nsmall = 6, scientific = FALSE), #Avoid scientific notation
           time = "12:00:00",
           date = format(date, "%Y%m%d"),
           output_data = paste0(date, "-", time, " ", flo_out, " ", water_temp))
  
  #Disconnect DB
  dbDisconnect(con) 
  
  # Export to text file
  write.table(df$output_data, file = output_file, row.names = FALSE, col.names = FALSE, quote = FALSE)
  
  message("File successfully written: ", output_file)
}

Conversion_SWAT_MITGCM_WaterQuantity(file1, output)
