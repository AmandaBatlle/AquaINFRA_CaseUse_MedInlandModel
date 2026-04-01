# data_download.R
print("download: Starting script download.R")

# Needs to be defined already (in the script that sources this script):
# * input_project (URL of zipped project directory, passed by user), e.g. "https://.../project.zip"
# * filename (name of the zipped file, but without extension/suffix), e.g. "project", but is used here as directory name...
# Rename them to avoid confusion:
url_zipped_project_file <- input_project
subdir_name <- filename

# Define file paths and URLs
# Target filename: Split URL by slash, take last item, i.e. the filename
dest_file_name <- tail(strsplit(url_zipped_project_file, "/")[[1]], 1)
# Target directory:
dest_dir <- paste0("../swat/Scenario_Gloria_linux/", subdir_name)
# Target directory with added filename, i.e. entire target path
dest_file_path <- paste0(dest_dir, "/", dest_file_name)
# Path of executable to be copied (TODO: Hardcoded! Need to change)
executable <- "../swat/Scenario_Gloria_linux/rev60.5.7_64rel_linux"

# Check if the file already exists and download if necessary
download_zipped_file <- function(url, project_dir, dest_file) {
  print(paste0('download: project_dir=', project_dir))
  print(paste0('download: filepath(..)=', file.path(project_dir, basename(executable))))
  print(paste0('download: getwd()=', getwd()))
  print(paste0('download: basename(executable)=', basename(executable)))
  print(paste0('download: executable=', executable))
  print(paste0('download: dest_file=', dest_file))

  if (file.exists(dest_file)) {
    print(paste0("download: File ", dest_file, " already exists. Skipping download."))
  } else {
    tryCatch(
      {
        # create containing dir:
        dir.create(project_dir)

        # download file as-is:
        print(paste0('download: Downloading file (to ', dest_file, ')...'))
        download.file(url, dest_file, mode = "wb")
        print(paste0('download: Downloading file (to ', dest_file, ')... done.'))

        # unzip
        print(paste0('download: Unzipping file...'))
        unzip_zipped_file(input_data_dir, project_dir)
        print(paste0('download: Unzipping file... done.'))

        #if (file.exists(executable)){
        #  print(paste0("download: EXISTS: ", executable))
        #}
        #if (file.exists(dest_file)){
        #  print(paste0("download: EXISTS: ", dest_file))
        #}
        #if (dir.exists("../swat/Scenario_Gloria_linux/project/")){
        #  print(paste0("download: EXISTS: ../swat/Scenario_Gloria_linux/project/"))
        #}

        # Copy executable
        print(paste0('download: Copying ', executable,' to ', file.path(project_dir, basename(executable)), '...'))
        #dest_exec <- file.path(project_dir, basename(executable))
        file.copy(executable, file.path(project_dir, basename(executable)), overwrite = TRUE)
        #Sys.chmod(dest_exec, mode = "0755")
        print(paste0("download: Copying ", executable, "... done."))
      },
      warning = function(warn) {
        message(paste("download: Warning: Download failed, reason: ", warn[1]))
        stop(paste("WARNING: Download failed, reason: ", warn[1]))
      },
      error = function(err) {
        message(paste("download: Error: Download of shapefile failed, reason: ", err[1]))
        stop(paste("ERROR: Download of shapefile failed, reason: ", err[1]))
      }
    ) # end trycatch
  } # end ifelse
}

# Function to unzip the downloaded file
unzip_zipped_file <- function(zip_file, unzip_dir) {
  tryCatch(
    {
      unzip(zip_file, exdir = unzip_dir)
      message(paste0("download: Unzipped to directory ", unzip_dir))
    },
    warning = function(warn) {
      msg <- paste("Warning: Unzipping failed, reason: ", warn[1])
      message(paste0("download: ", msg))
      stop(msg)
    },
    error = function(err) {
      msg <-paste("Error: Unzipping failed, reason: ", err[1])
      message(paste0("download: ", msg))
      stop(msg)
    }
  )
}

# Download and unzip shapefile
download_zipped_file(url_zipped_project_file, dest_dir, dest_file_path)
