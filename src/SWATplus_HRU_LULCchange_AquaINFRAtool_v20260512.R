
# ============================================================================ #
#                            AquaINFRA project                                 #
# ============================================================================ #
# Script name     : SWAT_LandUseChange_Scenario.R
# Description     : Tool to replace Land Use LLand Cover (LULC) for a selection of Hydrological Response Unit (HRU) in SWAT+ models. 
# Author          : Amanda Batlle Morera (a.batlle@creaf.uab.cat)
# Organization    : CREAF
# Date created    : 12-03-2026
# Last modified   : 12-05-2026
# R version       : 4.5.1 (2025-06-13 ucrt)
# ============================================================================= #

# AquaINFRA Mediterranean Case Use:  Mediterranean Inland Model, 
# SWAT+ LAND USE LAND COVER CHANGE TOOL.

# Required libraries:
#install.packages("zip")
library(zip)




# FUNCTION CHANGE LULC IN SELECTED HRU  ______________________________________________________####

# Description: This function will update the LULC categories in the hru_data.hru inside SWAT+ TxtInOut project. Based on the information contained on a csv file or polygons file ("shp","gpkg","geojson","json","kml","gml") 
# 
# Input: 
#   TxtInOut (string) Path to the TxtInOut directory
#   LULCchange: (dataframe) CSV file contang a list of HRU to change in the first column and new LULC assigned to each HRU on the second column. Or spatial layer file containing the polygon that delinieates the area affected by LULC change inside the watershed .
# 
# Output: 
#   Updated TxtInOut (object) TxtInOut directory zipped containg the updated "hru-data.hru" rewritten with the new LULC categories for the selected HRU.

run_hrululcc <- function ( LULCchange, TxtInOut) {
    
  # -------------------------
  # LOAD CHANGES
  # -------------------------
  #Renaming columns
    hru_id <- LULCchange[,1]
    new_lum <- LULCchange[,2]
    
    message(paste("run_hrululcc_process: hru to change:",  hru_id ))
    message(paste("run_hrululcc_process: new lulc to change:",  new_lum ))
            
    
  # -------------------------
  # APPLY CHANGE
  # -------------------------
    
    file = paste0(TxtInOut, "/hru-data.hru") 
    
    message(paste("run_hrululcc_process: Reading",  file ))
    lines <- readLines(file)
    
    # loop through all HRUs
    for(i in seq_along(hru_id)) {
      # find the line corresponding to this HRU
      row <- grep(paste0("^\\s*", hru_id[i], "\\s"), lines)
      
      if(length(row) == 0) {
        #warning(paste("HRU ID", hru_id[i], "not found"))
        next
      }
      
      message("run_hrululcc_process:Replace LULC in HRU ", hru_id[i], " to: ", new_lum[i])
      # replace the _lum word in that line
      lines[row] <- sub("[A-Za-z0-9]+_lum", paste0(new_lum[i], "_lum"), lines[row])
      
    }
    
    message("run_hrululcc_process:Rewrite hru-data.hru file with updated LULC")
    # write the modified lines back
    writeLines(lines, file)
  
  message("run_hrululcc_process:LULC change complete")
    
    # -------------------------
    # PROCESS OUTPUT
    # -------------------------
    
    # 1. Define exactly where the zip should go (Absolute path for Docker)
    # We put it directly into /out/ so Galaxy can find it
    final_zip_path <- file.path("/out", paste0(basename(TxtInOut), "_modified.zip"))
    
    message(paste("run_hrululcc_process: Creating zip at:", final_zip_path))
    
    # 2. Create the zip file
    # We change directory to inside TxtInOut so the zip doesn't have 
    # a "folder inside a folder" structure
    original_wd <- getwd()
    setwd(TxtInOut)
    zip::zip(zipfile = final_zip_path, files = list.files(all.files = TRUE, recursive = TRUE))
    setwd(original_wd)
    
    message("run_hrululcc_process: Zip creation complete.")
  
}



# INPUTS + example values
args <- commandArgs(trailingOnly = TRUE)
print(paste0('R Command line args: ', args))
url_zipped_input_project <- args[1]  # URL of zipped project file
url_input_lulcc          <- args[2]  # URL for LULC input data
download_path            <- args[3] # "/out/"

hrululcc_run_dir <- "../swat/current_hrululcc_run/" # (will be created and filled in this script)

# ______________________________________________________________________________
# Processing TxtInOut and calibration files download                        ####  
# ______________________________________________________________________________


# Download input project

# For downloading and unzipping, first define where it should go...
# Subdirectory name, derived from the URL:
subdir_name <- tools::file_path_sans_ext(basename(url_zipped_input_project))
# Target filename: Split URL by slash, take last item, i.e. the filename
dest_file_name <- tail(strsplit(url_zipped_input_project, "/")[[1]], 1)
# Target directory / project directory
# I assume that the subdir_name is not needed anymore!
dest_dir <- paste0(hrululcc_run_dir, subdir_name)
dir.create(hrululcc_run_dir)
# Target directory with added filename, i.e. entire target path
dest_file_path <- paste0(dest_dir, "/", dest_file_name)

# Now, get the download function and the function to copy the executable:
source("download.R")

# Now, download and unzip project file:
print(paste0("Downloading..."))
download_zipped_file(url_zipped_input_project, dest_dir, dest_file_path)
print(paste0("Downloading... done."))


# The project directory is the directory created by/before downloading
# and unzipping the zipped input project file:
#TxtInOut_Tordera <- paste0("../swat/Scenario_Gloria_linux/", subdir_name)
TxtInOut_Tordera <- dest_dir
print(paste("project directory", TxtInOut_Tordera))

print(paste0("Reading input csv..."))
  lulcc_csv <- read.csv(url_input_lulcc)
print(paste0("Reading input LULCC csv... done."))


#Csv example
run_hrululcc ( LULCchange = lulcc_csv, 
               TxtInOut = TxtInOut_Tordera)




