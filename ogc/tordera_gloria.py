import logging
import subprocess
import json
import os
from pathlib import Path
from pygeoapi.process.base import BaseProcessor, ProcessorExecuteError


LOGGER = logging.getLogger(__name__)

script_title_and_path = __file__
metadata_title_and_path = script_title_and_path.replace('.py', '.json')
PROCESS_METADATA = json.load(open(metadata_title_and_path))

class TorderaGloriaProcessor(BaseProcessor):

    def __init__(self, processor_def):
        super().__init__(processor_def, PROCESS_METADATA)
        self.supports_outputs = True
        self.my_job_id = 'nothing-yet'

    def set_job_id(self, job_id: str):
        self.my_job_id = job_id

    def __repr__(self):
        return f'<TorderaGloriaProcessor> {self.name}'

    def execute(self, data, outputs=None):

        # Get config
        config_file_path = os.environ.get('AQUAINFRA_CONFIG_FILE', "./config.json")
        with open(config_file_path, 'r') as configFile:
            configJSON = json.load(configFile)

        download_dir = configJSON["download_dir"]
        own_url = configJSON["own_url"]
        docker_executable = configJSON.get("docker_executable", "docker")

        # Get user inputs
        in_unit = data.get('unit')
        in_swat_file = data.get('file')
        in_variable = data.get('variable')
        in_start_date = data.get('start_date')
        in_end_date = data.get('end_date')
        in_start_date_print = data.get('start_date_print')

        # Check: TODO
        #if in_regions_url is None:
        #    raise ProcessorExecuteError('Missing parameter "regions". Please provide a URL to your input study area (as zipped shapefile).')
        #if in_dpoints_url is None:
        #    raise ProcessorExecuteError('Missing parameter "input_data". Please provide a URL to your input table.')

        downloadfilename_swat_output_file = 'swat_output_file-%s.csv' % self.my_job_id
        downloadfilename_parameter_calibration = 'parameter_calibration-%s.txt' % self.my_job_id
        
        returncode, stdout, stderr = run_docker_container(
            docker_executable,
            in_swat_file,
            in_variable,
            str(in_unit),
            str(in_start_date),
            str(in_end_date),
            str(in_start_date_print),
            download_dir, 
            downloadfilename_swat_output_file,
            downloadfilename_parameter_calibration
        )

        # print R stderr/stdout to debug log:
        for line in stdout.split("\n"):
            if not len(line.strip()) == 0:
                LOGGER.debug('R stdout: %s' % line)

        for line in stderr.split("\n"):
            if not len(line.strip()) == 0:
                LOGGER.debug('R stderr: %s' % line)

        if not returncode == 0:
            err_msg = 'Running docker container failed.'
            for line in stderr.split('\n'):
                if line.startswith('Error'): # TODO: Sometimes error messages span several lines.
                    err_msg = 'Running docker container failed: %s' % (line)
            raise ProcessorExecuteError(user_msg = err_msg)

        else:
            downloadlink_swat_output_file      = own_url.rstrip('/')+os.sep+"out"+os.sep+downloadfilename_swat_output_file
            downloadlink_parameter_calibration = own_url.rstrip('/')+os.sep+"out"+os.sep+downloadfilename_parameter_calibration
            response_object = {
                "outputs": {
                    "swat_output_file": {
                        "title": self.metadata['outputs']['swat_output_file']['title'],
                        "description": self.metadata['outputs']['swat_output_file']['description'],
                        "href": downloadlink_swat_output_file
                    },
                    "parameter_calibration": {
                        "title": self.metadata['outputs']['parameter_calibration']['title'],
                        "description": self.metadata['outputs']['parameter_calibration']['description'],
                        "href": downloadlink_parameter_calibration
                    },
                }
            }

            return 'application/json', response_object

def run_docker_container(
        docker_executable,
        in_swat_file,
        in_variable,
        in_unit,
        in_start_date,
        in_end_date,
        in_start_date_print,
        download_dir, 
        downloadfilename_swat_output_file,
        downloadfilename_parameter_calibration
    ):
    LOGGER.debug('Prepare running docker container')
    container_name = f'catalunya-tordera-image_{os.urandom(5).hex()}'
    image_name = 'catalunya-tordera-image'

    # Prepare container command

    # Define paths inside the container
    container_in = '/in'
    container_out = '/out'

    # Define local paths
    local_in = os.path.join(download_dir, "in")
    local_out = os.path.join(download_dir, "out")

    # Ensure directories exist
    os.makedirs(local_in, exist_ok=True)
    os.makedirs(local_out, exist_ok=True)

    script = 'SWATplus_Tordera_Gloria.R'

    print("------------------------------------------------")

    # Mount volumes and set command
    docker_command = [
        docker_executable, "run", "--rm", "--name", container_name,
        "-v", f"{local_in}:{container_in}",
        "-v", f"{local_out}:{container_out}",
        "-e", f"R_SCRIPT={script}",  # Set the R_SCRIPT environment variable
        image_name,
        "--",  # Indicates the end of Docker's internal arguments and the start of the user's arguments
        container_out,
        downloadfilename_swat_output_file,
        in_swat_file,
        in_variable,
        in_unit,
        in_start_date,
        in_end_date,
        in_start_date_print,
        downloadfilename_parameter_calibration
    ]

    LOGGER.debug('Docker command: %s' % docker_command)
    
    # Run container
    try:
        LOGGER.debug('Start running docker container')
        result = subprocess.run(docker_command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout = result.stdout.decode()
        stderr = result.stderr.decode()
        LOGGER.debug('Finished running docker container')
        return result.returncode, stdout, stderr

    except subprocess.CalledProcessError as e:
        LOGGER.debug('Failed running docker container')
        return e.returncode, e.stdout.decode(), e.stderr.decode()
