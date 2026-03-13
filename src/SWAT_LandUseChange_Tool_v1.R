
# ============================================================================ #
#                            AquaINFRA project                                 #
# ============================================================================ #
# Script name     : SWAT_LandUseChange_Scenario.R
# Description     : Tool to replace Land Use LLand Cover (LULC) for a selection of Hydrological Response Unit (HRU) in SWAT+ models. 
# Author          : Amanda Batlle Morera (a.batlle@creaf.uab.cat)
# Organization    : CREAF
# Date created    : 12-03-2026
# Last modified   : 13-03-2026
# R version       : 4.5.1 (2025-06-13 ucrt)
# ============================================================================= #

# AquaINFRA Mediterranean Case Use:  Mediterranean Inland Model, 
# SWAT+ LAND USE LAND COVER CHANGE TOOL.

# Required libraries:
#install.packages("sf")
library(sf)


# FUNCTION TO REWRITE HRU-DATA.HRU  ______________________________________________________####
# Description: This function reads the file hru_data.hru inside SWAT+ TxtInOut project and updated the Land Use Land Cover (LULC) of a group of selected HRU.
# 
# Input: 
#   file: (string) Complete path to "hru-data.hru" inside TxtInOut directory. 
#   hru_id: (vector) List of HRU ids that need LULC update
#   new_lum: (vector) List of new LULC categories to assign to each HRU.
# 
# Output: 
#   hru_data.hru (object) "hru-data.hru" inside TxtInOut directory will be rewritten with the new LULC categories for the selected HRU.


edit_hru_lum <- function(file, hru_id, new_lum){
  message("Reading hru-data.hru file. ")
  lines <- readLines(file)
  
  # loop through all HRUs
  for(i in seq_along(hru_id)) {
    # find the line corresponding to this HRU
    row <- grep(paste0("^\\s*", hru_id[i], "\\s"), lines)
    
    if(length(row) == 0) {
      #warning(paste("HRU ID", hru_id[i], "not found"))
      next
    }
    
    message("Replace LULC in HRU ", hru_id[i], " to: ", new_lum[i])
    # replace the _lum word in that line
    lines[row] <- sub("[A-Za-z0-9]+_lum", paste0(new_lum[i], "_lum"), lines[row])
    
  }
  
  message("Rewrite hru-data.hru file with updated LULC")
  # write the modified lines back
  writeLines(lines, file)
  
}



# FUNCTION CHANGE LULC IN SELECTED HRU  ______________________________________________________####

# Description: This function will update the LULC categories in the hru_data.hru inside SWAT+ TxtInOut project. Based on the information contained on a csv file or polygons file ("shp","gpkg","geojson","json","kml","gml") 
# 
# Input: 
#   LULCchange: (object) CSV file contang a list of HRU to change in the first column and new LULC assigned to each HRU on the second column. Or spatial layer file containing the polygon that delinieates the area affected by LULC change inside the watershed . Accepted spatial layer file formats are "shp" (contained in a zip file),"gpkg","geojson","json","kml", and"gml". 
#   HRU: (object) (Optional). If LULCchange is provided by a polygon file, the user will have to provide the HRU spatial layer file for the SWAT project. . Accepted spatial layer file formats are "shp" (contained in a zip file),"gpkg","geojson","json","kml", and"gml". 
#   new_lum: (string) (Optional). If LULCchange is provided by a polygon file, new LULC category to be assigned to the overlaping HRUs . 
#   TxtInOut (string) Path to the TxtInOut directory
# 
# Output: 
#   hru_data.hru (object) "hru-data.hru" inside TxtInOut directory will be rewritten with the new LULC categories for the selected HRU.

LULC_change_scenario <- function ( LULCchange, HRU=NA, new_lulc=NA, TxtInOut) {
  
  ext_LULC <- tolower(tools::file_ext(LULCchange))
  ext_HRU <- tolower(tools::file_ext(HRU))
  
  spatial_ext <- c("shp","gpkg","geojson","json","kml","gml","zip")
  # -------------------------
  # CSV WORKFLOW
  # -------------------------
  if ( ext_LULC == "csv" ) {
    
    message("Reading CSV file")
    changes_df <- read.csv(LULCchange, header = TRUE)
    
    hru_id <- changes_df[,1]
    new_lulc <- changes_df[,2]
    
  } 
  
  # -------------------------
  # SPATIAL WORKFLOW
  # -------------------------
  else if (ext_LULC %in% spatial_ext) {
    
    if (is.null(HRU)) stop("HRU must be provided when filetype='polygon'")
    if (is.null(new_lulc)) stop("new_lulc must be provided when filetype='polygon'")
    
    message("Reading LULC spatial layers")
    
    # Handle zipped shapefile
    if (ext_LULC == "zip") {
      
      tmp_dir <- tempfile()
      dir.create(tmp_dir)
      
      unzip(LULCchange, exdir = tmp_dir)
      
      shp <- list.files(tmp_dir, pattern="\\.shp$", full.names=TRUE)
      
      if (length(shp) == 0) stop("No shapefile found inside zip")
      
      LULCchange <- st_read(shp[1], quiet=TRUE)
      
    } else {
      
      LULCchange <- st_read(LULCchange, quiet=TRUE)
      
    }
    
    message("Reading HRU spatial layers")
    
    if (ext_HRU == "zip") {
      
      tmp_dir <- tempfile()
      dir.create(tmp_dir)
      
      unzip(HRU, exdir = tmp_dir)
      
      shp <- list.files(tmp_dir, pattern="\\.shp$", full.names=TRUE)
      
      if (length(shp) == 0) stop("No shapefile found inside zip")
      
      HRU <- st_read(shp[1], quiet=TRUE)
      
      if (any(!st_is_valid(HRU))) {
        message("Fixing invalid HRU geometries")
        # Fix invalid geometries
        HRU <- st_make_valid(HRU)
      }
      
    } else {
      
      HRU <- st_read(HRU, quiet=TRUE)
      
      if (any(!st_is_valid(HRU))) {
        message("Fixing invalid HRU geometries")
        # Fix invalid geometries
        HRU <- st_make_valid(HRU)
      }
      
    }
    
    # Match crs projection:
    if (st_crs(LULCchange) != st_crs(HRU)) {
      
      message("Reprojecting LULC change to match HRU CRS")
      LULCchange <- st_transform(LULCchange, st_crs(HRU))
      
    } else {
      
      message("CRS already matches")
      
    }
    
    # Fix LULC geometry
    if (any(!st_is_valid(LULCchange))) {
      message("Fixing invalid LULC polygons")
      # Fix invalid geometries
      LULCchange <- st_make_valid(LULCchange)

    }
    
    # Select intersecting HRUs
    message("Selecting intersecting HRUs")
    HRU_intersect <- st_intersection(HRU, LULCchange)
    
    hru_id <- HRU_intersect$HRUS
    
    message(length(hru_id), " HRUs selected")
    
  }
  
  else {
  
  stop("Unsupported LULC file format")
  
}
  # -------------------------
  # APPLY CHANGE
  # -------------------------

  edit_hru_lum ( file = paste0(TxtInOut, "/hru-data.hru"), 
                 hru_id = hru_id  , 
                 new_lum = new_lulc 
                 )
  
  message("LULC change complete, ready to run SWAT")
  
  
}


#Example test:

LULCchange_csv <- "lulc_changes.csv"
LULCchange_shp <- "Landchange_test.zip"
HRU_shp <- "C:/Users/a.batlle/OneDrive - CREAF/Documentos/local_AquaINFRA/SWATplus_Tordera/SWATplus/Model/swatplus_Tordera_5/Tordera_v5.1/Watershed/Shapes/hrus2.shp"

user_new_lulc <- "agrl"

TxtInOut_Tordera <-"9_surqlag20/TxtInOut"

#Csv example
LULC_change_scenario ( LULCchange = LULCchange_csv, 
                       TxtInOut = TxtInOut_Tordera)

#shp example
LULC_change_scenario ( LULCchange = LULCchange_shp, 
                       HRU= HRU_shp, 
                       new_lulc= user_new_lulc,
                       TxtInOut = TxtInOut_Tordera)



