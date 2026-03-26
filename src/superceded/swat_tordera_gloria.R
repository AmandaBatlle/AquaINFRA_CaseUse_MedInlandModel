# Amanda Batlle Morera (a.batll@creaf.uab.cat)

# AquaINFRA Mediterranean Case Use: 
# Step 1 Mediterranean Inland Model, SWAT+ TORDERA TOOL.

# If the package remotes is not installed, run first:
#install.packages('remotes', "dplyr", "jsonlite")
#remotes::install_github('chrisschuerz/SWATrunR')

library(SWATrunR)
library(dplyr)
library(jsonlite)

# INPUTS + example values
args <- commandArgs(trailingOnly = TRUE)
print(paste0('R Command line args: ', args))
input_project <- args[1]
input_calibration <- args[2]
fileout_from_user <- args[3] #"channel_sd_day"
variable_from_user <- strsplit(gsub(" ", "", args[4]), ",")[[1]] #"flo_out,water_temp"
unit_input <- gsub(" ", "", args[5])  # Remove spaces in unit input. Default 1

# Processing unit input to a correct format: 
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


start_date_from_user <- args[6] # 20160101
end_date_from_user <- args[7] # 20201231
start_date_print_from_user <- args[8] # 20190601
download_path <- args[9] #"/out/"


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

#SWATplus function
print(paste0("Defining function run_swat_process..."))
run_swat_process <- function (TxtInOut, 
                              fileout, 
                              variable, 
                              unit, 
                              startdate, 
                              enddate, 
                              printdate, 
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
                             start_date_print = printdate,
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
print(paste0("Defining function run_swat_process... done."))


#Run SWAT+ TORDERA tool
print(paste0("Running run_swat_process..."))
run_swat_process(TxtInOut_Tordera, 
                 fileout_from_user, 
                 variable_from_user, 
                 unit_from_user, 
                 start_date_from_user, 
                 end_date_from_user, 
                 start_date_print_from_user, 
                 par_cal,
                 download_path)
print(paste0("Running run_swat_process... done."))
#unlink(TxtInOut_Tordera, recursive = TRUE)


print(paste("R Script swat_tordera_gloria.R finished!"))
