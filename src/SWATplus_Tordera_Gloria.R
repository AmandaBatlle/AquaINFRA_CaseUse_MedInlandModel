# Amanda Batlle Morera (a.batll@creaf.uab.cat)

# AquaINFRA Case Study: Mediterranean Inland Model- SWAT+ TORDERA MODEL

# Load required libraries
library(SWATrunR) # To run SWAT
library(dplyr) # To convert data for export


# Funtion to run SWAt+ and process output

run_swat_process <- function(
  project_path, parameter_calibration, swat_file, variable, unit_number,
  start_date, end_date, start_date_print
  out_result_path, out_result_file) {

  #Run SWAT+ simulation
  message("Will store result to: ", out_result_path)
  message("Will name result as:  ", out_result_file)
  message("Running run_swatplus...")
  q_sim_plus <- run_swatplus(project_path = project_path,
                             output = define_output(file = swat_file,
                                                    variable = variable,
                                                    unit = unit_number),
                             start_date = start_date,
                             end_date =  end_date,
                             start_date_print = start_date_print,
                             parameter = parameter_calibration,
                             save_path = out_result_path,
                             save_file = out_result_file,
                             return_output = TRUE)
  message("Running run_swatplus... Done.")

  # check:
  message("Debug: Is the result NULL? ", is.null(q_sim_plus))
  head(q_sim_plus)
  message("Debug: Display the result:  ", q_sim_plus)
  
  # Process the output: rename the column to Sim_Flow
  # TODO: Test whether single pair of square brackets are enough?
  message("Renaming the result...")
  q_plus <- q_sim_plus$simulation[variable] %>%
    rename(Sim_Flow = run_1)  # Rename the output to Sim_Flow
  message("Renaming the result... Done.")
  
  return(q_plus)
  
}

# Executable has to be marked: (Done in Dockerfile)
# ‘chmod +x rev688_64rel_linux’ 

# Retrieve command line arguments
args <- commandArgs(trailingOnly = TRUE)
print(paste0('R Command line args: ', args))
out_result_path <- args[1]
out_result_file <- args[2]
swat_file <- args[3]
variable <- args[4]
unit_number <- args[5]
start_date <- args[6]
end_date <- args[7]
start_date_print <- args[8]
out_param_file <- args[9]


# Function call
project_path <- "/swat/Scenario_Gloria_linux"
# Parameter change
par_cal <- c("cn2.hru | change=absval" = -15.238,
              "esco.hru | change=absval" = 0.805,
              "canmx.hru | change=absval" = 81.537,
              "perco.hru | change=absval" = 0.892,
              "cn3_swf.hru | change=absval" = 0.819
              )

# Store parameter files to pass back to user
fileConn<-file(out_param_file)
writeLines(par_cal, fileConn)
close(fileConn)


q_plus_result <- run_swat_process(
  project_path, par_cal, swat_file, variable, unit_number,
  start_date, end_date, start_date_print
  out_result_path, out_result_file)

# View the result
head(q_plus_result)

