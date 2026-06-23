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
library(tools)

# Hardcoded relative paths that are used in this script:
# Path of executables to be copied (the relevant one must exist, otherwise an error occurs)
executable_src_path_swatplus <- "../swat/swatplus_executable/rev60.5.7_64rel_linux"
executable_src_path_swat2012 <- "../swat/swat2012_executable/rev688_64rel_linux"
# Name of directory to be used as project directory:
swat_run_dir <- "../swat/current_swat_run" # (will be created and filled in this script)
# Path of input csv files that are needed (must exist):
variablelist_path_plus <- "./in_variableList.csv"
variablelist_path_2012 <- "./in_variableList_swat2012.csv"
fileoutputlist_path    <- "./in_fileoutputList.csv"

# INPUTS + example values
args <- commandArgs(trailingOnly = TRUE)
message('R Command line args: ', paste(args, collapse=","))
swatversion_from_user    <- args[1]  # swatplus or swat2012
url_zipped_input_project <- args[2]  # URL of zipped project file
url_input_calibration    <- args[3]  # URL of json calibration file
fileout_from_user        <- args[4]  # "channel_sd_day"
variable_from_user       <- args[5]  # "flo_out,water_temp"
unit_input               <- args[6]  # Default 1
start_date_from_user     <- args[7]  # 20160101
end_date_from_user       <- args[8]  # 20201231
skipyears_from_user      <- args[9]  # 2
output_dir               <- args[10] # "/out/"


# Check validity of version:
valid_swat_versions <- c("swatplus", "swat2012")
if (swatversion_from_user %in% valid_swat_versions) {
  message("swat version is valid: ", swatversion_from_user)
} else {
  stop("Wrong SWAT version: Only acceptable variables are swatplus and swat2012")
}

# Convert "NULL" (string) to actual NULL:
if (url_input_calibration == "NULL") {
  message("No input calibration URL provided.")
  url_input_calibration <- NULL
}

# Remove spaces, split at comma:
variable_from_user <- strsplit(gsub(" ", "", variable_from_user), ",")[[1]]

# Remove spaces:
unit_input <- gsub(" ", "", unit_input)

# Make numeric:
skipyears_from_user   <- as.numeric(skipyears_from_user)
message("Skip years: ", skipyears_from_user)

# Output dir:
#message("Current working dir: ", getwd())
message("Will store to (rel.): ", output_dir)
message("Will store to (abs.): ", file_path_as_absolute(output_dir))
#message("Checking if exists: ", output_dir)
if (dir.exists(output_dir)) {
  message("Output directory does exist: ", output_dir)
} else {
  message("Creating output directory: ", output_dir)
  dir.create(output_dir, recursive = TRUE)
  message("Created output directory:  ", output_dir)
}



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

# Nothing to do

# ______________________________________________________________________________
# Processing TxtInOut and calibration files download                        ####  
# ______________________________________________________________________________


# Download input project

# For downloading and unzipping, first define where it should go...
# Subdirectory name, derived from the URL:
url_clean <- sub("\\?.*$", "", url_zipped_input_project)
subdir_name <- tools::file_path_sans_ext(basename(url_clean))
dest_file_name <- basename(url_clean)
# Target directory / project directory
# I assume that the subdir_name is not needed anymore!
dest_dir <- file.path(swat_run_dir, subdir_name)
dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
# Target directory with added filename, i.e. entire target path
dest_file_path <- file.path(dest_dir, dest_file_name)

# Now, get the download function and the function to copy the executable:
source("download.R")

# Now, download and unzip project file:
message("Downloading...")
download_zipped_file(url_zipped_input_project, dest_dir, dest_file_path)
if (swatversion_from_user == "swatplus") {
  mandatory_file = "time.sim"
} else if (swatversion_from_user == "swat2012") {
  mandatory_file = "file.cio"
}
dest_dir <- find_correct_path(target_file=mandatory_file, dest_dir)
message("Downloading... done. Using ", dest_dir, " (found ", mandatory_file, " in there).")

# Now, copy executable to newly created project directory
#message('Copying executable...')
#copy_executable(executable_src_path, dest_dir)
#message('Copying executable... done.')

# The project directory is the directory created by/before downloading
# and unzipping the zipped input project file:
#TxtInOut_Tordera <- file.path("../swat/Scenario_Gloria_linux", subdir_name)
TxtInOut_Tordera <- dest_dir
message("project directory", TxtInOut_Tordera)

message("Reading input calibration...")
if (is.null(url_input_calibration)) {
  message('The parameter calibration URL is null')
  par_cal <- NULL
} else {
  json_data <- fromJSON(url_input_calibration)
  par_cal <- unlist(json_data)
  message("Reading input calibration... done.")
}

# Define helper function to check if simulation output is there:
check_output_created <- function(q_sim, output_dir, version_string) {
  if (is.null(q_sim$simulation)) {
    msg <- "The simulation did not return any output."
    message(version_string, ": ", msg)
    stop(msg)
  } else if (file.exists(file.path(output_dir, "thread_1.sqlite"))) { # Check if the SQL file exists
    msg <- "The SWAT_output files were created successfully in the output directory."
    message(version_string, ": ", msg)
  } else {
    msg <- "The SWAT_output does not exist in the output directory."
    message(version_string, ": ", msg)
    stop(msg)
  }
}

# ______________________________________________________________________________
# Running the swatplus or swat2012 functions                                ####
# depending on version specified by user                                    ####
# ______________________________________________________________________________

if ( swatversion_from_user == "swatplus") {

  # copy SWAT plus executable into project folder:
  message('Copying executable...')
  copy_executable(executable_src_path_swatplus, TxtInOut_Tordera)
  message('Copying executable... done.')

  # ______________________________________________________________________________
  # SWATplus FUNCTION                                                         ####
  # ______________________________________________________________________________

  message("Defining function run_swatplus_process...")
  run_swatplus_process <- function (TxtInOut, 
                                    fileout, 
                                    variable, 
                                    unit, 
                                    startdate, 
                                    enddate, 
                                    skipyears, 
                                    par_comb, 
                                    output_dir) {

    message("run_swatplus_process: Starting...")

    # Review Input validity, by checking against a list read from a CSV file.
    message("run_swatplus_process: Reading csv file (in_fileoutputList.csv)...")
    valid_outputfile <- read.csv(fileoutputlist_path,
                                 sep = ";",
                                 stringsAsFactors = FALSE)
    message("run_swatplus_process: Reading csv file (in_fileoutputList.csv)... done.")
    message("run_swatplus_process: Checking valid inputs...")
    if (fileout %in% valid_outputfile$fileoutput) {
      message("run_swatplus_process: fileout: ", fileout, " is a valid input.")
    } else {
      msg <- paste("fileout", fileout, "is NOT a valid input. Review SWAT+ documentation for a valid input.")
      message("run_swatplus_process: ", msg)
      stop(msg)
    }
    message("run_swatplus_process: Checking valid inputs... done.")


    # Variable validity check.
    # TODO: This is very similar to how it is done in the swat2012 section, so make a function from it?
    # Read valid variable list
    message("run_swatplus_process: Reading csv file (in_variableList.csv)...")
    valid_variable <- read.csv(variablelist_path_plus, sep = ";" )
    message("run_swatplus_process: Reading csv file (in_variableList.csv)... done.")

    # Filter valid variables for the given output file
    message("run_swatplus_process: Filtering variables...")
    file <- strsplit(fileout, "_")[[1]][2]
    valid_variable_outputfile <- valid_variable[grepl(file, valid_variable$file), ]
    message("run_swatplus_process: Filtering variables... done.")

    # Iterate over variables to check them...
    message("run_swatplus_process: Iterating and checking variables (", paste(variable, collapse=", "), ")...")
    for (var_out in variable) {
      message("run_swatplus_process: Checking variable: ", var_out)
      if (var_out %in% valid_variable_outputfile$SWAT_variable) {
        message("run_swatplus_process: Variable: ", var_out," is a valid input.")
      } else if (var_out %in% valid_variable$SWAT_variable) {
        correct_fileoutput <- valid_variable$file[valid_variable$SWAT_variable == var_out]
        msg <- paste("Variable: ", var_out," Is not a valid input for fileout", fileout,
                     ".Variable",var_out, "belongs to outputfile", correct_fileoutput,
                     "Review SWAT+ documentation for a valid input.")
        message("run_swatplus_process: ", msg)
        stop(msg)
      } else {
        msg <- paste("Variable: ", var_out,"is NOT a valid SWAT variable.Review SWAT+ documentation for a valid input.")
        message("run_swatplus_process: ", msg)
        stop(msg)
      }
    }
    message("run_swatplus_process: Iterating and checking variables... done.")

    # Run SWAT+ simulation
    message("run_swatplus_process: Running run_swatplus(...).")
    q_sim_plus <- run_swatplus(project_path = TxtInOut,
                               output = define_output(file = fileout,
                                                      variable = variable,
                                                      unit = unit),
                               start_date= startdate,
                               end_date=enddate,
                               years_skip = skipyears,
                               parameter=par_comb,
                               save_path=output_dir,
                               save_file=""
    )
    message("run_swatplus_process: Running run_swatplus(...)... done.")

    # Check if simulation output exists
    message("run_swatplus_process: Content of result dir (", output_dir, "): ", paste(list.files(output_dir), collapse="+"))
    check_output_created(q_sim_plus, output_dir, "SWAT+")
  }
  message("Defining function run_swatplus_process... done.")






  # ______________________________________________________________________________
  # Run SWAT+ TORDERA tool                                                    ####
  # ______________________________________________________________________________

  message("Running run_swatplus_process...")
  run_swatplus_process(TxtInOut_Tordera,
                   fileout_from_user,
                   variable_from_user,
                   unit_from_user,
                   start_date_from_user,
                   end_date_from_user,
                   skipyears_from_user,
                   par_cal,
                   output_dir)
  message("Running run_swatplus_process... done.")
  #unlink(TxtInOut_Tordera, recursive = TRUE)


} else if (swatversion_from_user == "swat2012") {

  # copy SWAT2012 executable into project folder:
  message('Copying executable...')
  copy_executable(executable_src_path_swat2012, TxtInOut_Tordera)
  message('Copying executable... done.')


  # ______________________________________________________________________________
  # SWAT2012 FUNCTION                                                         ####
  # ______________________________________________________________________________

  message("Defining function run_swat2012_process...")
  run_swat2012_process <- function (TxtInOut,
                                    fileout,
                                    variable,
                                    unit,
                                    startdate,
                                    enddate,
                                    skipyears,
                                    par_comb,
                                    download_path) {

    message("run_swat2012_process: Starting...")

    # Review Input validity, by checking against hard-coded list of valid values.
    message("run_swat2012_process: review outputfile validity...")
    valid_outputfile <- c('rch', 'sub', 'hru','sed')
    file <- strsplit(fileout, "_")[[1]][1]
    if (file %in% valid_outputfile) {
      message("run_swat2012_process: fileout: ", fileout, " is a valid input.")
    } else {
      msg <- paste("fileout", fileout, "is NOT a valid input. Review SWAT2012 documentation for a valid input.")
      message("run_swat2012_process: ", msg)
      stop(msg)
    }

    # timestep validity check.
    message("run_swat2012_process: Loading valid time step...")
    valid_timestep <- c('d', 'm', 'y')
    timestep <- strsplit(fileout, "_")[[1]][2]
    if (timestep %in% valid_timestep) {
      message("run_swat2012_process: timestep: ", timestep, " is a valid input.")
    } else {
      msg <- paste("timestep", timestep, "is NOT a valid input. Review SWAT2012 documentation for a valid input.")
      message("run_swat2012_process: ", msg)
      stop(msg)
    }


    message("run_swat2012_process: Checking valid inputs... done.")


    # Variable validity check.
    # Read valid variable list
    message("run_swat2012_process: Reading csv file (in_variableList.csv)...")
    valid_variable <- read.csv (variablelist_path_2012, sep = ";" )
    message("run_swat2012_process: Reading csv file (in_variableList.csv)... done.")

    # Filter valid variables for the given output file
    message("run_swat2012_process: Filtering variables...")
    valid_variable_outputfile <- valid_variable[grepl(tolower(file), tolower(valid_variable$file)), ]
    message("run_swat2012_process: Filtering variables... done.")

    # Iterate over variables to check them...
    message("run_swat2012_process: Iterating and checking variables (", paste(variable, collapse=", "), ")...")
    for (var_out in variable) {
      message("run_swat2012_process: Checking variable: ", var_out)
      if (var_out %in% valid_variable_outputfile$SWAT_variable) {
        message("run_swat2012_process: Variable: ", var_out," is a valid input.")
      } else if (var_out %in% valid_variable$SWAT_variable) {
        correct_fileoutput <- valid_variable$file[valid_variable$SWAT_variable == var_out]
        msg <- paste("Variable: ", var_out," Is not a valid input for fileout", fileout,
                     ".Variable",var_out, "belongs to outputfile", correct_fileoutput,
                     "Review SWAT2012 documentation for a valid input.")
        message("run_swat2012_process: ", msg)
        stop(msg)
      } else {
        msg <- paste("Variable: ", var_out,"is NOT a valid SWAT variable.Review SWAT2012 documentation for a valid input.")
        message("run_swat2012_process: ", msg)
        stop(msg)
      }
    }
    message("run_swat2012_process: Iterating and checking variables... done.")


    # Run SWAT2012 simulation
    message("run_swat2012_process: Running run_swat2012(...).")
    # Here, neither save_path nor save_dir are defined. The output_dir
    # is not handed to the run_swat2012 function call! It is only used
    # to store the databases manually+explicitly, further below.
    q_sim_2012 <- run_swat2012(project_path = TxtInOut,
                               output = define_output(file = file,
                                                      variable = variable,
                                                      unit = unit),
                               start_date= as.Date(as.character(startdate), format = "%Y%m%d"),
                               end_date=as.Date(as.character(enddate), format = "%Y%m%d"),
                               years_skip = skipyears,
                               output_interval = timestep,
                               parameter = par_comb
    )

    #### NEED TO FIX THIS OUTPUT TO MATCH SWAT+ OUTPUT
    message("run_swat2012_process: Running run_swat2012(...)... done.")

    # Build sql output tables
    library(DBI)
    library(RSQLite)
    library(dplyr)
    library(purrr)

    # Build SWAT output table
    sim_list <- q_sim_2012$simulation

    run_table <- sim_list |>
      imap(function(df, name) {

        df |>
          rename(!!tolower(name) := run_1)

      }) |>
      reduce(left_join, by = "date")

    # Create SQLite database, in output_dir!
    con <- dbConnect(RSQLite::SQLite(), file.path(output_dir, "thread_1.sqlite"))

    # Write SQLite table
    dbWriteTable(
      con,
      "run_1_1.1",
      run_table,
      overwrite = TRUE
    )

    dbDisconnect(con)

    # Create inputs.sql file:
    # Extract data:
    run_info <- q_sim_2012$run_info
    output_definition <- run_info$output_definition
    simulation_log <- run_info$simulation_log
    simulation_period <- run_info$simulation_period

    # Create database, in output_dir!
    con <- dbConnect(RSQLite::SQLite(), file.path(output_dir, "inputs.sqlite"))

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

    # Check if simulation output exists
    message("run_swat2012_process: Content of result dir (", output_dir, "): ", paste(list.files(output_dir), collapse="+"))
    check_output_created(q_sim_2012, output_dir, "SWAT2012")

  }
  message("Defining function run_swat2012_process... done.")


  # ______________________________________________________________________________
  # Run SWAT2012 TORDERA tool                                                 ####
  # ______________________________________________________________________________

  message("Running run_swat2012_process...")
  run_swat2012_process(TxtInOut_Tordera,
                   fileout_from_user,
                   variable_from_user,
                   unit_from_user,
                   start_date_from_user,
                   end_date_from_user,
                   skipyears_from_user,
                   par_cal,
                   download_path)
  message("Running run_swat2012_process... done.")
  #unlink(TxtInOut_Tordera, recursive = TRUE)

}

message("R Script swat_tordera_gloria.R finished!")

