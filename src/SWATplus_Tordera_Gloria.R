# Amanda Batlle Morera (a.batll@creaf.uab.cat)

# AquaINFRA Case Study: Mediterranean Inland Model- SWAT+ TORDERA MODEL

# Load required libraries
library(SWATrunR) # To run SWAT
library(dplyr) # To convert data for export


# Funtion to run SWAt+ and process output

run_swat_process <- function (TxtInOut, par_comb, out_result_path, out_result_file) {
  #Run SWAT+ simulation
  message("Will store result to: ", out_result_path)
  message("Will name result as:  ", out_result_file)
  message("Running run_swatplus...")
  q_sim_plus <- run_swatplus(project_path = TxtInOut,
                             output = define_output(file = 'channel_sd_day',
                                                    variable = 'flo_out',
                                                    unit = 1),
                             start_date= 20160101,
                             end_date=20201231,
                             start_date_print = 20190601,
                            parameter=par_comb,
                            save_path = out_result_path,
                            save_file = out_result_file,
                            return_output = TRUE)
  message("Running run_swatplus... Done.")
  
  # Process the output: rename the column to Sim_Flow
  message("Renaming the result...")
  q_plus <- q_sim_plus$simulation$flo_out %>%
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



# Function call
path_TxtInOut <- "/swat/Scenario_Gloria_linux"
# Parameter change
par_cal <- c("cn2.hru | change=absval" = -15.238,
              "esco.hru | change=absval" = 0.805,
              "canmx.hru | change=absval" = 81.537,
              "perco.hru | change=absval" = 0.892,
              "cn3_swf.hru | change=absval" = 0.819
              )

q_plus_result <- run_swat_process(path_TxtInOut, par_cal, out_result_path, out_result_file)

# View the result
head(q_plus_result)

