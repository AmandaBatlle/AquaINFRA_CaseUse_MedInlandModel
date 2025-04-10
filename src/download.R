# data_download.R

# Define file paths and URLs
project_name <- tail(strsplit(input_project, "/")[[1]], 1)
project_dir <- paste0("../swat/Scenario_Gloria_linux/", filename)
input_data_dir <- paste0(project_dir, "/", project_name)
executable <- "../swat/Scenario_Gloria_linux/rev60.5.7_64rel_linux"

# Check if the file already exists and download if necessary
download_shapefile <- function(url, dest_file) {
  if (file.exists(dest_file)) {
    message(paste0("File ", dest_file, " already exists. Skipping download."))
  } else {
    tryCatch(
      {
        dir.create(project_dir)
        download.file(url, dest_file, mode = "wb")
        message(paste0("File ", dest_file, " downloaded."))
        unzip_shapefile(input_data_dir, project_dir)
        file.copy(executable, file.path(project_dir, basename(executable)), overwrite = TRUE)
      },
      warning = function(warn) {
        message(paste("Warning: Download of shapefile failed, reason: ", warn[1]))
      },
      error = function(err) {
        stop(paste("Error: Download of shapefile failed, reason: ", err[1]))
      }
    )
  }
}

# Function to unzip the downloaded file
unzip_shapefile <- function(zip_file, unzip_dir) {
    tryCatch(
      {
        unzip(zip_file, exdir = unzip_dir)
        message(paste0("Unzipped to directory ", unzip_dir))
      },
      warning = function(warn) {
        message(paste("Warning: Unzipping failed, reason: ", warn[1]))
      },
      error = function(err) {
        message(paste("Error: Unzipping failed, reason: ", err[1]))
      }
    )
}

# Download and unzip shapefile
download_shapefile(input_project, input_data_dir)
