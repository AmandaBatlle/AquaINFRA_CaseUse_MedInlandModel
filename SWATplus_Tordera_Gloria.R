# Amanda Batlle Morera (a.batll@creaf.uab.cat)

# AquaINFRA Case Study: Mediterranean Inland Model- SWAT+ TORDERA MODEL

# If the package remotes is not installed run first:
install.packages('remotes', "dplyr")

remotes::install_github('chrisschuerz/SWATrunR')

# Load required libraries
library(SWATrunR) # To run SWAT
library(dplyr) # To convert data for export


# Funtion to run SWAt+ and process output

run_swat_process <- function (TxtInOut) {
  #Run SWAT+ simulation
  q_sim_plus <- run_swatplus(project_path = TxtInOut,
                             output = define_output(file = 'channel_sd_mon',
                                                    variable = 'flo_out',
                                                    unit = 1))
  
  # Process the output: rename the column to Sim_Flow
  q_plus <- q_sim_plus$simulation$flo_out %>%
    rename(Sim_Flow = run_1)  # Rename the output to Sim_Flow
  
  return(q_plus)
  
}

# Executable has to be marked:
# ‘chmod +x rev688_64rel_linux’ 


# Example of how to call the function
path_TxtInOut <- "C:/Users/a.batlle/OneDrive - CREAF/Documentos/local_AquaINFRA/SWATrunR_model/Tordera_Data/Scenario_Gloria_windows"
q_plus_result <- run_swat_process(path_TxtInOut)

# View the result
head(q_plus_result)

