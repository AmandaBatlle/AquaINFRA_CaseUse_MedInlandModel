# Author: Amanda Batlle Morera (a.batll@creaf.uab.cat)
# AquaINFRA Case Study: Mediterranean Inland Model - SWAT+ TORDERA MODEL

# Install required libraries only if not already installed
if (!requireNamespace("SWATrunR", quietly = TRUE)) remotes::install_github('chrisschuerz/SWATrunR')

library(SWATrunR)
library(dplyr)
library(readr)

run_swat_process <- function(
    project_path, parameter_calibration, swat_file, variable, unit_number,
    start_date, end_date, start_date_print) {
  
  # Run SWAT+ simulation
  message("Executing SWAT+ simulation...")
  q_sim_plus <- run_swatplus(
    project_path = project_path,
    output = define_output(
      file = swat_file,
      variable = variable,
      unit = unit_number
    ),
    start_date = start_date,
    end_date = end_date,
    start_date_print = start_date_print,
    parameter = parameter_calibration
  )
  message("SWAT+ simulation completed.")
  
  # Rename the result variable for clarity
  message("Processing simulation results...")
  q_plus <- q_sim_plus$simulation[[variable]] %>% rename(Sim_Flow = run_1)
  message("Results processed successfully.")
  
  return(q_plus)
}

# Ensure executable permissions are set (Handled in Dockerfile)
# Command: chmod +x rev688_64rel_linux

args <- commandArgs(trailingOnly = TRUE)
print(paste0('R Command line arguments: ', args))

swat_file <- args[1]
variable <- args[2]
unit_number <- as.integer(args[3])  # Convert to integer
start_date <- args[4]
end_date <- args[5]
start_date_print <- args[6]
out_result_file <- args[7]

project_path <- "../swat/swatplus_rev60_demo"

# Define parameter modifications for calibration
par_cal <- c(
  "cn2.hru | change=absval" = -15.238,
  "esco.hru | change=absval" = 0.805,
  "canmx.hru | change=absval" = 81.537,
  "perco.hru | change=absval" = 0.892,
  "cn3_swf.hru | change=absval" = 0.819
)

q_plus_result <- run_swat_process(
  project_path, par_cal, swat_file, variable, unit_number,
  start_date, end_date, start_date_print
)

# Save result to a CSV file
output_csv <- file.path(out_result_file)
write_csv(q_plus_result, output_csv)
message("Results saved to: ", output_csv)