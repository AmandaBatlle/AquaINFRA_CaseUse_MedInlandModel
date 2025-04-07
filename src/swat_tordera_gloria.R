# Amanda Batlle Morera (a.batll@creaf.uab.cat)

# AquaINFRA Mediterranean Case Use: 
# Step 1 Mediterranean Inland Model, SWAT+ TORDERA TOOL.

# If the package remotes is not installed run first:
#install.packages('remotes', "dplyr")
#remotes::install_github('chrisschuerz/SWATrunR')

library(SWATrunR)
library(dplyr)

# INPUTS + example values
args <- commandArgs(trailingOnly = TRUE)
print(paste0('R Command line args: ', args))
fileout_from_user <- args[1] #"channel_sd_day"
variable_from_user <- strsplit(args[2], ",")[[1]] #"flo_out,water_temp"
unit_from_user <- as.numeric(args[3]) # 1
start_date_from_user <- args[4] # 20160101
end_date_from_user <- args[5] # 20201231
start_date_print_from_user <- args[6] # 20190601
download_path <- args[7] #"/out/"
download_names <- strsplit(args[8], ",")[[1]] #"flow_out.csv,water_temp.csv"

# FIX INPUT SWAT+ TORDERA TOOL: 
#In a second round of implementation we can include the capability to opload your own TextInOut folder and your own parameters to run a model of a different watersheed.
# But by the moment I think it is better to keep it fixed. 
TxtInOut_Tordera <- "../swat/Scenario_Gloria_linux/"

# Parameter calibration 1: 
# Calibration performed by Amanda Batlle Morera (CREAF) a.batlle@creaf.uab.cat
# Calibration process: 
#     - Soft calibration: qualitative evaluation of annual average values.
#     - Automatic calibration at separated landscape units using observed dad from Catalan Water Agencia gauge data (Agència Catalana de l'Aigua: aca.gencat.cat )
# NOTE AMANDA: THIS CALIBRATION VALUES WILL BE CHANGED WHEN FINAL VERSION OF THE MODEL IS AVAILABLE.

par_cal <- c("cn2.hru | change=absval" = -15.238,
             "esco.hru | change=absval" = 0.805,
             "canmx.hru | change=absval" = 81.537,
             "perco.hru | change=absval" = 0.892,
             "cn3_swf.hru | change=absval" = 0.819,
             "awc.sol | change=absval" = -2.853,
             "k.sol | change=absval" = -0.342)

#SWATplus function
run_swat_process <- function (TxtInOut, 
                              fileout, 
                              variable, 
                              unit, 
                              startdate, 
                              enddate, 
                              printdate, 
                              par_comb, 
                              download_path, 
                              download_filenames) {
  # Review Input validity. 
  valid_outputfile <- read.csv ("in_fileoutputList.csv", 
                                sep = ";",
                                stringsAsFactors = FALSE)

  if (fileout %in% valid_outputfile$fileoutput) {
    print(paste("fileout:", fileout,"is a valid input."))
  } else {
    print(paste("fileout", fileout,"is NOT a valid input. Review SWAT+ documentation for a valid input."))
  }
        
  # variable validity check.
  # Conevert to 
  # Read valid variable list
  valid_variable <- read.csv ("in_variableList.csv", sep = ";" )
  # Filter valid variables for the given output file
  file <- strsplit(fileout, "_")[[1]][2]
  valid_variable_outputfile <- valid_variable[grepl(file, valid_variable$file), ] 
  
  for (var_out in variable_from_user) {
    if (var_out %in% valid_variable_outputfile$SWAT_variable) {
      print(paste("Variable: ", var_out,"is a valid input."))
    } else if (var_out %in% valid_variable$SWAT_variable) {
      correct_fileoutput <- valid_variable$file[valid_variable$SWAT_variable == var_out]
      stop(paste("Variable: ", var_out," Is not a valid input for fileout", fileout,".Variable",var_out, "belongs to outputfile", correct_fileoutput,"Review SWAT+ documentation for a valid input."))
    }else{
      stop(paste("Variable: ", var_out,"is NOT a valid SWAT variable.Review SWAT+ documentation for a valid input."))
    }
  } 
  
  #Run SWAT+ simulation
  q_sim_plus <- run_swatplus(project_path = TxtInOut,
                             output = define_output(file = fileout,
                                                    variable = variable,
                                                    unit = unit),
                             start_date= startdate,
                             end_date=enddate,
                             start_date_print = printdate,
                             parameter=par_comb
  )
  # Check if simulation output exists
  if (is.null(q_sim_plus$simulation)) {
    stop("SWAT+ simulation did not return any output.")
  }
  
  # Process the output: Iterate over the elements in variable vector
  for (i in seq_along(variable_from_user)) {
    var_out <- variable_from_user[i]
    file_name <- paste0(download_path, download_filenames[i])
    if (!var_out %in% names(q_sim_plus$simulation)) {
      warning(paste("Variable", var_out, "not found in simulation output. Skipping..."))
      next  # Skip this iteration if the variable does not exist
    }
    
    q_plus <- q_sim_plus$simulation[[var_out]]  # Extract dynamically
    
    # Convert to data frame if necessary
    if (!is.data.frame(q_plus)) {
      q_plus <- data.frame(run_1 = q_plus)
    }
    
    # Rename dynamically
    q_plus <- q_plus %>% rename_with(~ var_out, all_of("run_1"))
    
    # Write CSV file
    write.csv(q_plus, file = file_name, row.names = FALSE)
    
    # Check if the file exists and has data
    if (file.exists(file_name)) {
      file_data <- read.csv(file_name)  # Read file to check content
      
      if (nrow(file_data) > 0) {
        print(paste("Simulation of variable", var_out, "saved successfully."))
      } else {
        warning(paste("File", file_name, "was created but is empty."))
      }
    } else {
      warning(paste("File", file_name, "was not created."))
    }
  }
}

#Run SWAT+ TORDERA tool
run_swat_process(TxtInOut_Tordera, 
                 fileout_from_user, 
                 variable_from_user, 
                 unit_from_user, 
                 start_date_from_user , 
                 end_date_from_user, 
                 start_date_print_from_user, 
                 par_cal,
                 download_path,
                 download_names)