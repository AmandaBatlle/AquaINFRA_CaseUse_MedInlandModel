# ============================================================================ #
#                            AquaINFRA project                                 #
# ============================================================================ #
# Script name     : swat_galaxy_tool_v3.R
# Description     : This code executes SWAT+ or SWAT2012. 
# Author          : Amanda Batlle Morera (a.batlle@creaf.uab.cat)
# Organization    : CREAF
# Date created    : 08-05-2025
# Last modified   : 13-03-2026
# R version       : 4.5.1 (2025-06-13 ucrt)
# ============================================================================= #
# AquaINFRA Mediterranean Case Use: 
# Step 1 Mediterranean Inland Model, SWAT+ TORDERA TOOL.

# If the package remotes is not installed, run first:
#install.packages('remotes', "dplyr", "jsonlite", "DBI", "RSQLite", "purrr")
#remotes::install_github('chrisschuerz/SWATrunR')

library(SWATrunR)
library(dplyr)
library(jsonlite)

# INPUTS + example values
args <- commandArgs(trailingOnly = TRUE)
print(paste0('R Command line args: ', args))
swatversion_from_user <- args[1] # swatplus or swat2012
input_project <- args[2]
input_calibration <- args[3]
fileout_from_user <- args[4] #"channel_sd_day"
variable_from_user <- strsplit(gsub(" ", "", args[5]), ",")[[1]] #"flo_out,water_temp"
unit_input <- gsub(" ", "", args[6])  # Remove spaces in unit input. Default 1



# ______________________________________________________________________________
# Processing unit input to a correct format:                                #### 
# ______________________________________________________________________________

# Handle combined unit input like "1:3,5,7"
  if (grepl(":", unit_input) && grepl(",", unit_input)) {
    # Split by commas
    ranges <- strsplit(unit_input, ",")[[1]]
    unit_from_user <- numeric(0)  # Initialize an empty numeric vector
    for (range in ranges) {
      if (grepl(":", range)) {
        # Handle range like "1:3"
        unit_from_user <- c(unit_from_user, eval(parse(text = range)))
      } else {
        # Handle individual numbers like "5" or "7"
        unit_from_user <- c(unit_from_user, as.numeric(range))
      }
    }
  } else if (grepl("^\\d+:\\d+$", unit_input)) {
    # Handle ranges like "1:10"
    unit_from_user <- eval(parse(text = unit_input))
  } else {
    # Otherwise, treat it as comma-separated numbers
    unit_from_user <- as.numeric(strsplit(unit_input, ",")[[1]])
  }


# ______________________________________________________________________________
# Processing modelling time                                                 ####
# ______________________________________________________________________________
start_date_from_user <- args[7] # 20160101
end_date_from_user <- args[8] # 20201231
skipyears_from_user  <- args[9] # 2


# ______________________________________________________________________________
# Processing TxtInOut and calibration files download                        ####  
# ______________________________________________________________________________

download_path <- args[10] #"/out/"


#Download input project
filename <- tools::file_path_sans_ext(basename(input_project))
# Note: filename is needed by download.R. Maybe rather call function instead of source?
print(paste0("Downloading..."))
source("download.R")
print(paste0("Downloading... done."))

TxtInOut_Tordera <- paste0("../swat/Scenario_Gloria_linux/", filename)
print(paste("project directory", TxtInOut_Tordera))

print(paste0("Reading input calibration..."))
json_data <- fromJSON(input_calibration)
par_cal <- unlist(json_data)
print(paste0("Reading input calibration... done."))



if ( swatversion_from_user == "swatplus") {
# copy SWAT plus executable into project folder: 
  file.copy(from = "/swat/Scenario_Gloria_linux/rev60.5.7_64rel_linux",
          to   = TxtInOut_Tordera)
  # ______________________________________________________________________________
  #  SWATplus FUNCTION                                                        ####
  # _____________________________________________________________________________

  print(paste0("Defining function run_swatplus_process..."))
  run_swatplus_process <- function (TxtInOut, 
                                    fileout, 
                                    variable, 
                                    unit, 
                                    startdate, 
                                    enddate, 
                                    skipyears, 
                                    par_comb, 
                                    download_path) {
    
    print(paste0("run_swat_process: Starting..."))
    
    # Review Input validity. 
    print(paste0("run_swat_process: Reading csv file (in_fileoutputList.csv)..."))
    valid_outputfile <- read.csv ("in_fileoutputList.csv", 
                                  sep = ";",
                                  stringsAsFactors = FALSE)
    print(paste0("run_swat_process: Reading csv file (in_fileoutputList.csv)... done."))
    print(paste0("run_swat_process: Checking valid inputs..."))
    if (fileout %in% valid_outputfile$fileoutput) {
      print(paste("run_swat_process: fileout:", fileout, "is a valid input."))
    } else {
      msg <- paste("fileout", fileout, "is NOT a valid input. Review SWAT+ documentation for a valid input.")
      print(paste("run_swat_process:", msg))
      stop(msg)
    }
    print(paste0("run_swat_process: Checking valid inputs... done."))
    
    
    # Variable validity check.
    # Read valid variable list
    print(paste0("run_swat_process: Reading csv file (in_variableList.csv)..."))
    valid_variable <- read.csv ("in_variableList.csv", sep = ";" )
    print(paste0("run_swat_process: Reading csv file (in_variableList.csv)... done."))
    
    # Filter valid variables for the given output file
    print(paste0("run_swat_process: Filtering variables..."))
    file <- strsplit(fileout, "_")[[1]][2]
    valid_variable_outputfile <- valid_variable[grepl(file, valid_variable$file), ] 
    print(paste0("run_swat_process: Filtering variables... done."))
    
    # Iterate over variables to check them...
    print(paste0("run_swat_process: Iterating and checking variables (", paste(variable, collapse=", "), ")..."))
    for (var_out in variable) {
      print(paste0("run_swat_process: Checking variable: ", var_out))
      if (var_out %in% valid_variable_outputfile$SWAT_variable) {
        print(paste("run_swat_process: Variable: ", var_out,"is a valid input."))
      } else if (var_out %in% valid_variable$SWAT_variable) {
        correct_fileoutput <- valid_variable$file[valid_variable$SWAT_variable == var_out]
        msg <- paste("Variable: ", var_out," Is not a valid input for fileout", fileout,
                     ".Variable",var_out, "belongs to outputfile", correct_fileoutput,
                     "Review SWAT+ documentation for a valid input.")
        print(paste("run_swat_process:", msg))
        stop(msg)
      }else{
        msg <- paste("Variable: ", var_out,"is NOT a valid SWAT variable.Review SWAT+ documentation for a valid input.")
        print(paste("run_swat_process:", msg))
        stop(msg)
      }
    }
    print(paste0("run_swat_process: Iterating and checking variables... done."))
    
    
    # Output dir:
    output_dir <- file.path("../../../out", download_path)
    print(paste0("run_swat_process: Will store to: ", output_dir))
    print(paste0("run_swat_process: Checking if exists: ", output_dir))
    if (dir.exists(output_dir)) {
      print(paste0("run_swat_process: Does exist: ", output_dir))
    } else {
      print(paste0("run_swat_process: Creating: ", output_dir))
      dir.create(output_dir, recursive = TRUE)
      print(paste0("run_swat_process: Created:  ", output_dir))
    }
    
    
    #Run SWAT+ simulation
    print(paste0("run_swat_process: Running run_swatplus(...)."))
    q_sim_plus <- run_swatplus(project_path = TxtInOut,
                               output = define_output(file = fileout,
                                                      variable = variable,
                                                      unit = unit),
                               start_date= startdate,
                               end_date=enddate,
                               years_skip = skipyears,
                               parameter=par_comb,
                               save_file=output_dir
    )
    print(paste0("run_swat_process: Running run_swatplus(...)... done."))
    print(paste0("run_swat_process: Content of result dir (", output_dir, "): ", paste(list.files(output_dir), collapse="+")))
    
    
    # Check if simulation output exists
    #print(paste0("run_swat_process: Did SWAT+ return any output? ", is.null(q_sim_plus$simulation)))
    if (is.null(q_sim_plus$simulation)) {
      stop("SWAT+ simulation did not return any output.")
    } else if (file.exists(paste0(output_dir, "thread_1.sqlite"))) { # Check if the SQL file exists
      print("run_swat_process: The SWAT_output files were created successfully.")
    } else {
      msg <- "The SWAT_output does not exist."
      print(paste("run_swat_process:", msg))
      stop(msg)
    }
  }
  print(paste0("Defining function run_swatplus_process... done."))
  
  
  
  
  
  
  # ______________________________________________________________________________
  #Run SWAT+ TORDERA tool                                                     ####
  # ______________________________________________________________________________
  print(paste0("Running run_swatplus_process..."))
  run_swatplus_process(TxtInOut_Tordera, 
                   fileout_from_user, 
                   variable_from_user, 
                   unit_from_user, 
                   start_date_from_user, 
                   end_date_from_user, 
                   skipyears_from_user , 
                   par_cal,
                   download_path)
  print(paste0("Running run_swatplus_process... done."))
  #unlink(TxtInOut_Tordera, recursive = TRUE)

  
} else if (swatversion_from_user == "swat2012") {
    # copy SWAT2012 executable into project folder: 
  file.copy(from = "/swat/swat2012scenario/rev688_64rel_linux",
          to   = TxtInOut_Tordera)

  # ______________________________________________________________________________
  #  SWAT2012 FUNCTION                                                        ####
  # ______________________________________________________________________________  
  print(paste0("Defining function run_swat2012_process..."))
  run_swat2012_process <- function (TxtInOut, 
                                    fileout, 
                                    variable, 
                                    unit, 
                                    startdate, 
                                    enddate, 
                                    skipyears, 
                                    par_comb, 
                                    download_path) {
    
    message(paste0("run_swat2012_process: Starting..."))
    
    # Review Input validity. 
    message(paste0("run_swat2012_process: review outputfile validity..."))
    valid_outputfile <- c('rch', 'sub', 'hru','sed')
    file <- strsplit(fileout, "_")[[1]][1]
    if (file %in% valid_outputfile) {
      message(paste("run_swat2012_process: fileout:", fileout, "is a valid input."))
    } else {
      msg <- paste("fileout", fileout, "is NOT a valid input. Review SWAT2012 documentation for a valid input.")
      message(paste("run_swat2012_process:", msg))
      stop(msg)
    }
    
    # timestep validity check.
    message(paste0("run_swat_process: Loading valid time step..."))
    valid_timestep <- c('d', 'm', 'y')
    timestep <- strsplit(fileout, "_")[[1]][2]
    if (timestep %in% valid_timestep) {
      print(paste("run_swat2012_process: timestep:", timestep, "is a valid input."))
    } else {
      msg <- paste("timestep", timestep, "is NOT a valid input. Review SWAT2012 documentation for a valid input.")
      print(paste("run_swat2012_process:", msg))
      stop(msg)
    }
    
    
    message(paste0("run_swat_process: Checking valid inputs... done."))
    
    
    # Variable validity check.
    # Read valid variable list
    message(paste0("run_swat2012_process: Reading csv file (in_variableList.csv)..."))
    valid_variable <- read.csv ("in_variableList_swat2012.csv", sep = ";" )
    message(paste0("run_swat2012_process: Reading csv file (in_variableList.csv)... done."))
    
    # Filter valid variables for the given output file
    message(paste0("run_swat2012_process: Filtering variables..."))
    valid_variable_outputfile <- valid_variable[grepl(tolower(file), tolower(valid_variable$file)), ]
    message(paste0("run_swat2012_process: Filtering variables... done."))
    
    # Iterate over variables to check them...
    message(paste0("run_swat2012_process: Iterating and checking variables (", paste(variable, collapse=", "), ")..."))
    for (var_out in variable) {
      message(paste0("run_swat2012_process: Checking variable: ", var_out))
      if (var_out %in% valid_variable_outputfile$SWAT_variable) {
        message(paste("run_swat2012_process: Variable: ", var_out,"is a valid input."))
      } else if (var_out %in% valid_variable$SWAT_variable) {
        correct_fileoutput <- valid_variable$file[valid_variable$SWAT_variable == var_out]
        msg <- paste("Variable: ", var_out," Is not a valid input for fileout", fileout,
                     ".Variable",var_out, "belongs to outputfile", correct_fileoutput,
                     "Review SWAT2012 documentation for a valid input.")
        message(paste("run_swat2012_process:", msg))
        stop(msg)
      }else{
        msg <- paste("Variable: ", var_out,"is NOT a valid SWAT variable.Review SWAT2012 documentation for a valid input.")
        message(paste("run_swat2012_process:", msg))
        stop(msg)
      }
    }
    message(paste0("run_swat2012_process: Iterating and checking variables... done."))
    
    
    # Output dir:
    output_dir <- file.path("../../../out", download_path)
    message(paste0("run_swat2012_process: Will store to: ", output_dir))
    message(paste0("run_swat2012_process: Checking if exists: ", output_dir))
    if (dir.exists(output_dir)) {
      message(paste0("run_swat2012_process: Does exist: ", output_dir))
    } else {
      message(paste0("run_swat2012_process: Creating: ", output_dir))
      dir.create(output_dir, recursive = TRUE)
      message(paste0("run_swat2012_process: Created:  ", output_dir))
    }
    
    
    #Run SWAT2012 simulation
    message(paste0("run_swat2012_process: Running run_swatplus(...)."))
    q_sim_2012 <- run_swat2012(project_path = TxtInOut,
                               output = define_output(file = file,
                                                      variable = variable,
                                                      unit = unit),
                               start_date= startdate,
                               end_date=enddate,
                               years_skip = skipyears,
                               output_interval = timestep ,
                               parameter=par_comb
    )
    
    #### NEED TO FIX THIS OUTPUT TO MATCH SWAT+ OUTPUT
    message(paste0("run_swat2012_process: Running run_swat2012(...)... done."))
    
    # Build sql output tables
    
    library(DBI)
    library(RSQLite)
    library(dplyr)
    library(purrr)
    
    #Build SWAT output table
    sim_list <- q_sim_2012$simulation
    
    run_table <- sim_list |>
      imap(function(df, name) {
        
        df |>
          rename(!!tolower(name) := run_1)
        
      }) |>
      reduce(left_join, by = "date")
    
    # Create SQLite database
    con <- dbConnect(RSQLite::SQLite(), paste0(output_dir,"/thread_1.sqlite"))
    
    # Write SQLite table
    
    dbWriteTable(
      con,
      "run_1_1.1",
      run_table,
      overwrite = TRUE
    )
    
    dbDisconnect(con)
    
    #Create inout.sql file:  
    
    #Extract data: 
    run_info <- q_sim_2012$run_info
    
    output_definition <- run_info$output_definition
    simulation_log <- run_info$simulation_log
    simulation_period <- run_info$simulation_period
    
    # Create database
    con <- dbConnect(RSQLite::SQLite(), paste0(output_dir,"/inputs.sqlite"))
    
    # Write data
    dbWriteTable(
      con,
      "output_definition",
      output_definition,
      overwrite = TRUE
    )
    
    dbWriteTable(
      con,
      "simulation_log",
      simulation_log,
      overwrite = TRUE
    )
    
    dbWriteTable(
      con,
      "simulation_period",
      simulation_period,
      overwrite = TRUE
    )
    
    dbDisconnect(con)
    
    message(paste0("run_swat2012_process: Content of result dir (", output_dir, "): ", paste(list.files(output_dir), collapse="+")))
    
    
    # Check if simulation output exists
    #message(paste0("run_swat_process: Did SWAT+ return any output? ", is.null(q_sim_plus$simulation)))
    if (is.null(q_sim_2012$simulation)) {
      stop("SWAT2012 simulation did not return any output.")
    } else if (file.exists(paste0(output_dir, "thread_1.sqlite"))) { # Check if the SQL file exists
      message("run_swat_process: The SWAT_output files were created successfully.")
    } else {
      msg <- "The SWAT_output does not exist."
      message(paste("run_swat_process:", msg))
      stop(msg)
    }
  }
  message(paste0("Defining function run_swat2012_process... done."))
  
  
  # ______________________________________________________________________________
  #Run SWAT2012 TORDERA tool                                                     ####
  # ______________________________________________________________________________
  print(paste0("Running run_swat2012_process..."))
  run_swat2012_process(TxtInOut_Tordera, 
                   fileout_from_user, 
                   variable_from_user, 
                   unit_from_user, 
                   start_date_from_user, 
                   end_date_from_user, 
                   skipyears_from_user , 
                   par_cal,
                   download_path)
  print(paste0("Running run_swat2012_process... done."))
  #unlink(TxtInOut_Tordera, recursive = TRUE)
  
  
} else {
  print("Wrong SWAT version: Only acceptable variables are swatplus and swat2012")
}

print(paste("R Script swat_tordera_gloria.R finished!"))








