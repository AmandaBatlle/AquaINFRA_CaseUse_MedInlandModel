import logging
import subprocess
import json
import os
from pathlib import Path
from pygeoapi.process.base import BaseProcessor, ProcessorExecuteError

'''
How to call this process:

curl -i -X POST "http://localhost:5000/processes/tordera-gloria/execution" \
  --header "Content-Type: application/json" \
  --header 'Prefer: respond-async'
  --data '{
  "inputs":{
        "TextInOut_URL": "https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/project.zip",
        "par_cal": "https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/par_cal.json",
        "unit": 1,
        "file": "channel_sd_day",
        "variable": "flo_out,water_temp",
        "start_date": 20160101,
        "end_date": 20160228,
        "start_date_print": 20160115
    }
}'

'''

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
        in_project = data.get('TextInOut_URL') or "https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/project.zip"
        in_parameter_cal = data.get('par_cal') or "https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/par_cal.json"
        in_swat_file = data.get('file') or "channel_sd_day"
        in_variable = data.get('variable') or "flo_out,water_temp" 
        in_unit = data.get('unit') or 1
        in_start_date = data.get('start_date') or 20160101
        in_end_date = data.get('end_date') or 20160228
        in_start_date_print = data.get('start_date_print') or 20160115

        downloadFolder = f'/{self.my_job_id}/'

        returncode, stdout, stderr, user_err_msg = run_docker_container(
            docker_executable,
            in_project,
            in_parameter_cal,
            in_swat_file,
            in_variable.replace(" ", ""),
            str(in_unit),
            str(in_start_date),
            str(in_end_date),
            str(in_start_date_print),
            download_dir, 
            downloadFolder
        )

        # print R stderr/stdout to debug log:
        LOGGER.debug('___R stdout___')
        for line in stdout.split("\n"):
            if not len(line.strip()) == 0:
                LOGGER.debug('R stdout: %s' % line)

        LOGGER.debug('___R stderr___')
        for line in stderr.split("\n"):
            if not len(line.strip()) == 0:
                LOGGER.debug('R stderr: %s' % line)

        if not returncode == 0:

            user_err_msg = "no message" if len(user_err_msg) == 0 else user_err_msg
            err_msg = 'Running docker container failed: %s' % user_err_msg

            very_debug = False # TODO: This is only a temporary solution!
            if very_debug:
                # TODO: This prints all the content to the response. Remove this after debug period!
                err_msg = 'Running docker container failed. Stderr: ' + ' - '.join(stderr.split('\n'))

            raise ProcessorExecuteError(user_msg = err_msg)

        else:
            LOGGER.debug('Finished running Docker container, now preparing the results to be sent back to client.')
            downloadlink = own_url.rstrip('/')
            response_object = {
                "outputs": {
                    "swat_output_summary": {
                        "title": self.metadata['outputs']['swat_output_summary']['title'],
                        "description": self.metadata['outputs']['swat_output_summary']['description'],
                        "href": f'{downloadlink}{downloadFolder}out/inputs.sqlite'
                    },
                    "swat_output_file": {
                        "title": self.metadata['outputs']['swat_output_file']['title'],
                        "description": self.metadata['outputs']['swat_output_file']['description'],
                        "href": f'{downloadlink}{downloadFolder}out/thread_1.sqlite'
                    }
                }
            }

            LOGGER.debug('Returning results to caller.')
            return 'application/json', response_object

def run_docker_container(
        docker_executable,
        in_project_folder,
        in_calibration_parameter,
        in_swat_file,
        in_variable,
        in_unit,
        in_start_date,
        in_end_date,
        in_start_date_print,
        download_dir,
        download_folder
    ):
    LOGGER.debug('Prepare running docker container')
    container_name = f'catalunya-tordera-image_{os.urandom(5).hex()}'
    image_name = 'catalunya-tordera-image'

    # Prepare container command

    # Define paths inside the container
    container_in = '/in'
    container_out = '/out/'

    # Define local paths
    local_in = os.path.join(download_dir, "in")
    local_out = os.path.join(download_dir, "out")

    # Ensure directories exist
    os.makedirs(local_in, exist_ok=True)
    os.makedirs(local_out, exist_ok=True)

    script = 'swat_tordera_gloria.R'

    # Mount volumes and set command
    docker_command = [
        docker_executable, "run", "--rm", "--name", container_name,
        "-v", f"{local_in}:{container_in}",
        "-v", f"{local_out}:{container_out}",
        "-e", f"R_SCRIPT={script}",  # Set the R_SCRIPT environment variable
        image_name,
        "--",  # Indicates the end of Docker's internal arguments and the start of the user's arguments
        in_project_folder,
        in_calibration_parameter,
        in_swat_file,
        in_variable,
        in_unit,
        in_start_date,
        in_end_date,
        in_start_date_print,
        download_folder
    ]

    LOGGER.debug('Docker command: %s' % docker_command)
    print(docker_command)
    
    # Run container
    try:
        LOGGER.debug('Start running docker container')
        result = subprocess.run(docker_command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout = result.stdout.decode()
        stderr = result.stderr.decode()
        LOGGER.debug('Finished running docker container')
        return result.returncode, stdout, stderr, "no error"

    except subprocess.CalledProcessError as e:
        returncode = e.returncode
        stdout = e.stdout.decode()
        stderr = e.stderr.decode()
        LOGGER.error('Failed running docker container (exit code %s)' % returncode)
        user_err_msg = get_error_message_from_docker_stderr(stderr)
        return returncode, stdout, stderr, user_err_msg


def get_error_message_from_docker_stderr(stderr, log_all_lines = True):
    '''
    We would like to return meaningful messages to users. For example, by
    printing ALL stderr lines, we get the following:

    R stderr: Error in download_shapefile(input_project, input_data_dir) :
    R stderr:   object 'warn' not found

    Now, how to capture the meaningful part of that, which we want to return
    to the user? Here is a first attempt:
    '''

    user_err_msg = ""
    error_on_previous_line = False
    colon_on_previous_line = False
    for line in stderr.split('\n'):

        # Skip empty lines:
        if not line:
            continue

        # Print all non-empty lines to log:
        if log_all_lines:
            LOGGER.error('Docker stderr: %s' % line)

        # R error messages may start with the word "Error"
        if line.startswith("Error"):
            #LOGGER.debug('### Found explicit error line: %s' % line.strip())
            user_err_msg += line.strip()
            error_on_previous_line = True

        # When R error messages are continued on another line, they may be
        # indented by two spaces.
        elif line.startswith("  ") and error_on_previous_line:
            #LOGGER.debug('### Found indented line following an error: %s' % line.strip())
            user_err_msg += " "+line.strip()
            error_on_previous_line = True

        # When R error messages end with a colon, they will be continued on
        # the next line, independently of their indentation I guess!
        elif colon_on_previous_line and error_on_previous_line:
            #LOGGER.debug('### Found line following a colon: %s' % line.strip())
            user_err_msg += " "+line.strip()
            error_on_previous_line = True

        else:
            #LOGGER.debug('### Do not pass back to user: %s' % line.strip())
            error_on_previous_line = False

        # Remember whether this line ended with a colon, indicating that the
        # next line will continue with the error message:
        colon_on_previous_line = False
        if line.strip().endswith(":"):
            #LOGGER.debug('### Found a colon, next line will still be error!')
            colon_on_previous_line = True

    return user_err_msg
