# data_download.R
message("download: Starting script download.R")

# Check if the file already exists and download if necessary
download_zipped_file <- function(url, dest_dir, dest_file_path) {
  message('download: dest_dir=', dest_dir)
  message('download: getwd()=', getwd())
  message('download: dest_file_path=', dest_file_path)

  # create containing dir:
  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }

  if (file.exists(dest_file_path)) {
    message("download: File ", dest_file_path, " already exists. Skipping download.")
  } else {
    tryCatch(
      {
        # download file as-is:
        message('download: Downloading file (to ', dest_file_path, ')...')
        download.file(url, dest_file_path, mode = "wb")
        message('download: Downloading file (to ', dest_file_path, ')... done.')

        # unzip
        message('download: Unzipping file...')
        unzip_zipped_file(dest_file_path, dest_dir)
        message('download: Unzipping file... done.')

        #if (file.exists(executable)){
        #  message("download: EXISTS: ", executable)
        #}
        #if (file.exists(dest_file_path)){
        #  message("download: EXISTS: ", dest_file_path)
        #}
        #if (dir.exists("../swat/Scenario_Gloria_linux/project/")){
        #  message("download: EXISTS: ../swat/Scenario_Gloria_linux/project/")
        #}
      },
      warning = function(warn) {
        message(paste("download: Warning: Download failed, reason: ", warn[1]))
        stop(paste("WARNING: Download failed, reason: ", warn[1]))
      },
      error = function(err) {
        message(paste("download: Error: Download failed, reason: ", err[1]))
        stop(paste("ERROR: Download failed, reason: ", err[1]))
      }
    ) # end trycatch
  } # end ifelse
}

# Function to unzip the downloaded file
unzip_zipped_file <- function(zip_file, unzip_dir) {
  tryCatch(
    {
      unzip(zip_file, exdir = unzip_dir)
      message("download: Unzipped to directory ", unzip_dir)
    },
    warning = function(warn) {
      msg <- paste("Warning: Unzipping failed, reason: ", warn[1])
      message("download: ", msg)
      stop(msg)
    },
    error = function(err) {
      msg <-paste("Error: Unzipping failed, reason: ", err[1])
      message("download: ", msg)
      stop(msg)
    }
  )
}

# Function to copy executable to destination dir
copy_executable <- function(executable_src_path, dest_dir) {
  message('download: Starting to copy executable into newly created project directory...')

  # Define filename and paths:
  executable_filename <- basename(executable_src_path)
  executable_target_path <- file.path(dest_dir, executable_filename)
  message('download: executable_src_path=', executable_src_path)
  message('download: executable_filename=', executable_filename)
  message('download: executable_target_path=', executable_target_path)

  # Check existence:
  if (!(file.exists(executable_src_path))) {
    stop(paste0('Executable file does not exist in expected location (', executable_src_path, ')'))
  }

  # Copy executable
  message('download: Copying ', executable_src_path,' to ', executable_target_path, '...')
  #dest_exec <- file.path(dest_dir, basename(executable))
  copy_success <- file.copy(executable_src_path, executable_target_path, overwrite = TRUE)
  #Sys.chmod(dest_exec, mode = "0755")
  if (copy_success) {
    message("download: Copying ", executable_src_path, "... done.")
  } else {
    stop(paste0("download: Copying ", executable_src_path, "... FAILED."))
  }
}


