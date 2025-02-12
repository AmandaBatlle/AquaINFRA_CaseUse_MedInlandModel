# Amanda Batlle Morera (a.batll@creaf.uab.cat)

# AquaINFRA Case Study: Mediterranean Inland Model- SWAT+ TORDERA MODEL

# If the package remotes is not installed run first:
#install.packages('remotes', "dplyr")

#remotes::install_github('chrisschuerz/SWATrunR')

# Load required libraries
library(SWATrunR) # To run SWAT
library(dplyr) # To convert data for export


# Funtion to run SWAt+ and process output

run_swat_process <- function (TxtInOut) {
  #Run SWAT+ simulation
  message("Debug: Running run_swatplus...")
  q_sim_plus <- run_swatplus(project_path = TxtInOut,
                             output = define_output(file = 'channel_sd_day',
                                                    variable = 'flo_out',
                                                    unit = 1))

  message("Debug: Running run_swatplus... Done.")

  # check:
  message("Debug: Is the result NULL? ", is.null(q_sim_plus))
  head(q_sim_plus)
  message("Debug: Display the result:  ", q_sim_plus)
  
  # Process the output: rename the column to Sim_Flow
  q_plus <- q_sim_plus$simulation$flo_out %>%
    rename(Sim_Flow = run_1)  # Rename the output to Sim_Flow
  
  return(q_plus)
  
}

# Executable has to me marked as executable
# ‘chmod +x rev688_64rel_linux’ 


# Example of how to call the function
#path_TxtInOut <- "C:/Users/a.batlle/OneDrive - CREAF/Documentos/local_AquaINFRA/SWATrunR_model/Tordera_Data/Scenario_Gloria_windows"
path_TxtInOut <- "./swat/swatplus_rev60_demo"
q_plus_result <- run_swat_process(path_TxtInOut)

# View the result
head(q_plus_result)

# Link to this file on GitHub:
# Repo:
# https://github.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel
# Commit da2a3a7738031ad280e4a27b4b9e79c5dda54131
# https://github.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/blob/da2a3a7738031ad280e4a27b4b9e79c5dda54131/SWATplus_Tordera_Gloria.R
# RAW:
# https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/da2a3a7738031ad280e4a27b4b9e79c5dda54131/SWATplus_Tordera_Gloria.R?token=GHSAT0AAAAAAC46STGBXSDKWLEGMDJBKJVKZ5LHW7A
