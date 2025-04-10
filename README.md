# AquaINFRA_CaseUse_MedInlandModel

[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/HEAD)

AquaINFRA Case Study: Mediterranean Inland Model

Gloria Scenario SWATplus model:
- Code: swat_tordera_gloria.R 
- Project Data: https://github.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/tree/main/swat/Scenario_Gloria_linux
- La Tordera shapefiles: Download and unzip https://drive.google.com/file/d/1gFPHRyKm2SaGwG6xHtL8uzNFC_0_vF78/view?usp=sharing

## Running analysis in R

Step 1:

`Rscript swat_tordera_gloria.R https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/project.zip https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/par_cal.json "channel_sd_day" "flo_out,water_temp" 1 20160101 20201231 20190601 "./" "flo_out.csv,water_temp.csv"`

Step 1 (Quick run):

`Rscript swat_tordera_gloria.R https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/project.zip https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/par_cal.json "channel_sd_day" "flo_out,water_temp" 1 20160101 20160228 20160115 "./" "flo_out.csv,water_temp.csv"`

Step 2:

`Rscript swat_mitgcm_connection.R https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/flo_out.csv https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/water_temp.csv joinedFile.txt`

## Running analysis using Docker

Step 1:

`docker run -it -v ./in:/in -v ./out:/out -e R_SCRIPT="swat_tordera_gloria.R" catalunya-tordera-image -- "https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/project.zip" "https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/par_cal.json" "channel_sd_day" "flo_out,water_temp" 1 20160101 20201231 20190601 "/out/" "flo_out.csv,water_temp.csv"`

Step 1 (Quick run):

`docker run -it -v ./in:/in -v ./out:/out -e R_SCRIPT="swat_tordera_gloria.R" catalunya-tordera-image -- "https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/project.zip" "https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/par_cal.json" "channel_sd_day" "flo_out,water_temp" 1 20160101 20160228 20160115 "/out/" "flo_out.csv,water_temp.csv"`

Step 2:

`docker run -it -v ./in:/in -v ./out:/out -e R_SCRIPT="swat_mitgcm_connection.R" catalunya-tordera-image -- https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/flo_out.csv https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/water_temp.csv "../out/joined.txt"`

## How to dockerize

You can make a Docker image from this code as follows:

* You need the SWAT executables and calibration to run SWAT with. Here we assume you can download it from somewhere (link is above)
* First, install docker according to docker documentation.
* The run the following commands:

```
# Clone this directory
git clone git@github.com:AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel.git
cd AquaINFRA_CaseUse_MedInlandModel

# Get the input data, unzip it into "swat" directory:
cd swat
wget https://..../Scenario_Gloria_linux.zip
unzip Scenario_Gloria_linux.zip

# Build the image
today=$(date '+%Y%m%d')
docker build -t catalunya-tordera-image:${today} .
docker build -t catalunya-tordera-image:latest .
```

## How to deploy as OGC service on pygeoapi

* You need a pygeoapi instance running! Please deploy it according to the pygeoapi documentation.
* Then go into processes directory: `cd pygeoapi/pygeoapi/processes`
* Clone this repo there and build the image (as above).
* Add the service to the `plugin.py` (under `'process'`): `'TorderaGloriaProcessor': 'pygeoapi.process.AquaINFRA_CaseUse_MedInlandModel.ogc.tordera_gloria.TorderaGloriaProcessor',`
* Add the service to `pygeoapi-config.yml` (under `resources:`):

```
    tordera-gloria:
        type: process
        processor:
           name: TorderaGloriaProcessor
```

* Create a `config.yml` inside the pygeoapi base directory, containing the following items:

```
{
    "docker_executable": "/usr/bin/docker", # how pygeoapi can call docker to run containers!
    "download_dir": "/var/www/nginx/download/", # directory where to store the results so users can download them! Depends on your server settings...
    "own_url": "https://aquainfra.ogc.igb-berlin.de/download/", # the URL to give back to users, where they can download the results stored in 'download_dir'

}
```

* You may have to make sure that pygeoapi is allowed to run docker containers. This may include adding the Linux user that runs the pygeoapi instance to the Linux group `docker`.
* Now you may have to reinstall / restart pygeoapi (so it knows about these recently added services), depending on your pygeoapi installation.
* The service should be available on localhost (and possibly from outside):

```
curl -X POST "http://localhost:5000/processes/tordera-gloria/execution" --header "Content-Type: application/json" --data '{
  "inputs": {
    "unit": 1,
    "file": "channel_sd_day",
    "variable": "flo_out",
    "start_date": 20160101,
    "end_date": 20201231,
    "start_date_print": 20190601
    }
}'
```

(If this example is not up to date, a more up to date example should be located in the respective pygeoapi process file: https://github.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/blob/main/ogc/tordera_gloria.py)

## Contact

AquaINFRA project, WP 4 and 5
