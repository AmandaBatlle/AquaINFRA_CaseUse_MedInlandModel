# data_download.R
print("download: Starting script download.R")

# Define file paths and URLs
project_name <- tail(strsplit(input_project, "/")[[1]], 1)
project_dir <- paste0("../swat/Scenario_Gloria_linux/", filename)
input_data_dir <- paste0(project_dir, "/", project_name)
executable <- "../swat/Scenario_Gloria_linux/rev60.5.7_64rel_linux"

# Check if the file already exists and download if necessary
download_shapefile <- function(url, dest_file) {
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
        dir.create(project_dir)
        print(paste0('download: Downloading file (to ', dest_file, ')...'))
        download.file(url, dest_file, mode = "wb")
        print(paste0('download: Downloading file (to ', dest_file, ')... done.'))
        print(paste0('download: Unzipping file...'))
        unzip_shapefile(input_data_dir, project_dir)
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

	print(paste0('download: Copying ', executable,' to ', file.path(project_dir, basename(executable)), '...'))
	file.copy(executable, file.path(project_dir, basename(executable)), overwrite = TRUE)
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
unzip_shapefile <- function(zip_file, unzip_dir) {
    tryCatch(
      {
        unzip(zip_file, exdir = unzip_dir)
        print(paste0("download: Unzipped to directory ", unzip_dir))
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
download_shapefile(input_project, input_data_dir)
