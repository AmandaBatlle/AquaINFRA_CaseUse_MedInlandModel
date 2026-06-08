# AquaINFRA_CaseUse_MedInlandModel

[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/HEAD)

AquaINFRA Case Study: Mediterranean Inland Model

Gloria Scenario SWATplus model:
- Code: `SWATrunR_AquaINFRAtool_v20260313.R` (previously: `swat_tordera_gloria.R`)
- Project Data: https://github.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/tree/main/swat/Scenario_Gloria_linux
- La Tordera shapefiles: Download and unzip https://drive.google.com/file/d/1gFPHRyKm2SaGwG6xHtL8uzNFC_0_vF78/view?usp=sharing

## Running analysis in R

Step 1:

```
# old (needs fixing/testing/discarding)
Rscript swat_tordera_gloria.R https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/project.zip https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/par_cal.json "channel_sd_day" "flo_out,water_temp" 1 20160101 20201231 20190601 "./"
```

Step 1 (Quick run):

```
# old (needs fixing/testing/discarding)
Rscript swat_tordera_gloria.R https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/project.zip https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/par_cal.json "channel_sd_day" "flo_out,water_temp" 1 20160101 20160228 20160115 "./"
```

Step 2:

```
# old (needs fixing/testing/discarding)
Rscript swat_mitgcm_connection.R https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_results/thread_1.sqlite joinedFile.txt
```

## Running analysis using Docker

Note: For this, you need to build a docker image first! See below on how to do that.
Here, we assume you build a docker image under the name of `catalunya-tordera:20260608-1eccf57`.
These steps were tested with commit `1eccf57` on 2026-06-08.

Step 1 (swat2012):

```
# works (2026-06-08)
date; docker run -v ./test_out_swat2012:/out/ -e "R_SCRIPT=SWATrunR_AquaINFRAtool_v20260313.R" catalunya-tordera:20260608-1eccf57 -- "swat2012" "https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/swat2012_sampledata.zip" "NULL" "rch_m" "FLOW_OUT" "1" "20000101" "20030228" "2" "/"; date

# old (needs fixing/testing/discarding)
#docker run -it -v ./in:/in -v ./out:/out -e R_SCRIPT="swat_tordera_gloria.R" catalunya-tordera-image -- "https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/project.zip" "https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/par_cal.json" "channel_sd_day" "flo_out,water_temp" 1 20160101 20201231 20190601 "/jobid123/"
```

Step 1 (swatplus):

```
# works (2026-06-08)
# Note: This takes about 15 minutes to finish
date; docker run -v ./test_out_swatplus:/out/ -e "R_SCRIPT=SWATrunR_AquaINFRAtool_v20260313.R" catalunya-tordera:20260608-1eccf57 -- "swatplus" "https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/project.zip" "https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/par_cal.json" "channel_sd_day" "flo_out,water_temp" "1" "20140101" "20160228" "2" "/"; date
```

Step 1 (Quick run):

```
# old (needs fixing/testing/discarding)
#docker run -it -v ./in:/in -v ./out:/out -e R_SCRIPT="swat_tordera_gloria.R" catalunya-tordera-image -- "https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/project.zip" "https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/par_cal.json" "channel_sd_day" "flo_out,water_temp" 1 20160101 20201231 20190601 "/jobid123/"
```

Step 2:

```
# old (needs fixing/testing/discarding)
date; docker run -it -v ./in:/in -v ./out:/out -e R_SCRIPT="swat_mitgcm_connection.R" catalunya-tordera-image -- https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_results/thread_1.sqlite "../out/joined.txt"
```

## How to dockerize

This is how you build the docker image before running a docker container.
We include today's date and commit hash to the image name, but if you build
in a later moment, possibly based on another git commit, your image name may
be different.

Note: In case you made any changes to the R source code, you will need to re-build the image.

```
# Clone this directory
git clone git@github.com:AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel.git
cd AquaINFRA_CaseUse_MedInlandModel

# Example build command:
# This includes the git commit hash, so please
# make sure all your changes are committed/stashed:
today=$(date '+%Y%m%d')
githash=$(git rev-parse --short HEAD)
# or:
# githash="dev"
docker build \
  --build-arg GIT_COMMIT=${githash} \
  -t catalunya-tordera:${today}-${githash} .

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
    "download_url": "https://aquainfra.ogc.igb-berlin.de/download/", # the URL to give back to users, where they can download the results stored in 'download_dir'

}
```

* You may have to make sure that pygeoapi is allowed to run docker containers. This may include adding the Linux user that runs the pygeoapi instance to the Linux group `docker`.
* Now you may have to reinstall / restart pygeoapi (so it knows about these recently added services), depending on your pygeoapi installation.
* The service should be available on localhost (and possibly from outside). If it is available from outside, use your URL: `PYSERVER="my-host.com/pygeoapi"`.
* Now you can test it with the curl commands below:


## How to make an HTTP POST request to run this on pygeoapi

Please use any tool you like that can make HTTP POST requests. On Linux, `curl` is
a frequently used tool. On Windows, you may want to try `postman`. There are really
many tools, find your preferred one on the internet.


**swat2012:**


```
# first, specify where to reach the service:
PYSERVER=localhost:5000
PYSERVER="my-host.com/pygeoapi"

# this one is relatively fast:
curl -X POST https://${PYSERVER}/processes/tordera-gloria/execution  \
  --header "Content-Type: application/json" \
  --data '{
    "inputs":{
        "swat_version": "swat2012",
        "TextInOut_URL": "https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/swat2012_sampledata.zip",
        "par_cal": null,
        "file": "rch_m",
        "variable": "FLOW_OUT",
        "unit": 1,
        "start_date": 20000101,
        "end_date":   20030228,
        "skip_years": 2
    }
}'
```

**swatplus:**

```
# first, specify where to reach the service:
PYSERVER=localhost:5000
PYSERVER="my-host.com/pygeoapi"

# this takes about 15 minutes and will probably run into a timeout:
curl -X POST https://${PYSERVER}/processes/tordera-gloria/execution \
  --header "Content-Type: application/json" \
  --data '{
    "inputs": {
        "swat_version": "swatplus",
        "TextInOut_URL": "https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/project.zip",
        "par_cal":       "https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/par_cal.json",
        "file": "channel_sd_day",
        "variable": "flo_out,water_temp",
        "unit": 1,
        "start_date": 20140101,
        "end_date":   20160228,
        "skip_years": 2
    }
}'

# to avoid the timeout, run this in asynchronous mode: Request the
# computation, then poll for status updates at the URL that is returned
# in the HTTP response header "location" (using -i to print the response headers):
curl -i -X POST https://${PYSERVER}/processes/tordera-gloria/execution \
  --header "Content-Type: application/json" \
  --header 'Prefer: respond-async' \
  --data '{
    "inputs": {
        "swat_version": "swatplus",
        "TextInOut_URL": "https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/project.zip",
        "par_cal":       "https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/par_cal.json",
        "file": "channel_sd_day",
        "variable": "flo_out,water_temp",
        "unit": 1,
        "start_date": 20140101,
        "end_date":   20160228,
        "skip_years": 2
    }
}'
```

Old (to be fixed/tested/discarded):

```
curl -i -X POST https://${PYSERVER}/processes/tordera-gloria/execution \
  --header "Content-Type: application/json" \
  --header 'Prefer: respond-async' \
  --data '{
    "inputs": {
        "TextInOut_URL": "https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/project.zip",
        "par_cal": "https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/water_temp.csv",
        "unit": 1,
        "file": "channel_sd_day",
        "variable": "flo_out,water_temp,no3_out",
        "start_date": 20160101,
        "end_date": 20201231,
        "start_date_print": 20190601
    }
}'
```
