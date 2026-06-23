import logging
import subprocess
import json
import os
from pathlib import Path
from pygeoapi.process.base import BaseProcessor, ProcessorExecuteError

'''
How to call this process:

# swatplus
# TESTED 2026-06-08: Works
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

# swat2012:
# TESTED 2026-06-08: Works
curl -i -X POST https://${PYSERVER}/processes/tordera-gloria/execution  \
  --header "Content-Type: application/json" \
  --header 'Prefer: respond-async' \
  --data '{
    "inputs": {
        "swat_version": "swat2012",
        "TextInOut_URL": "https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/swat2012_sampledata.zip",
        "file": "rch_m",
        "variable": "FLOW_OUT",
        "unit": 1,
        "start_date": 20000101,
        "end_date":   20030228,
        "skip_years": 2
    }
}'

# OR:
# swat2012: Same, but explicitly state "par_cal": null
# TESTED 2026-06-08: Works
curl -i -X POST https://${PYSERVER}/processes/tordera-gloria/execution  \
  --header "Content-Type: application/json" \
  --header 'Prefer: respond-async' \
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

'''

LOGGER = logging.getLogger(__name__)

script_title_and_path = __file__
metadata_title_and_path = script_title_and_path.replace('.py', '.json')
PROCESS_METADATA = json.load(open(metadata_title_and_path))

class TorderaGloriaProcessor(BaseProcessor):

    def __init__(self, processor_def):
        super().__init__(processor_def, PROCESS_METADATA)
        self.supports_outputs = True
        self.job_id = 'nothing-yet'
        self.process_id = self.metadata["id"]
        self.image_name = 'catalunya-tordera:20260608-1eccf57'
        self.script_name = 'SWATrunR_AquaINFRAtool_v20260313.R'
        config_file_path = os.environ.get('AQUAINFRA_CONFIG_FILE', "./config.json")
        with open(config_file_path, 'r') as config_file:
            config = json.load(config_file)
            self.download_dir = config["download_dir"].rstrip('/')
            self.download_url = config["download_url"].rstrip('/')
            self.docker_executable = config.get("docker_executable", "docker")

    def set_job_id(self, job_id: str):
        self.job_id = job_id

    def __repr__(self):
        return f'<TorderaGloriaProcessor> {self.name}'

    def execute(self, data, outputs=None):

        #################################
        ### Get user inputs and check ###
        #################################

        in_project = data.get('TextInOut_URL')
        in_parameter_cal = data.get('par_cal')
        in_swat_version = data.get('swat_version')
        in_swat_file = data.get('file')
        in_variable = data.get('variable')
        in_unit = data.get('unit')
        in_start_date = data.get('start_date')
        in_end_date = data.get('end_date')
        in_skip_years = data.get('skip_years')

        # TODO: Parse/validate dates?

        # Validate
        if not in_swat_version in ['swatplus', 'swat2012']:
            raise ProcessorExecuteError(f"Unknown value for 'swatversion': {in_swat_version}. Must be either 'swatplus' or 'swat2012'.")

        # Set defaults:
        if in_project is None:
            raise ProcessorExecuteError('Missing parameter: TextInOut_URL')
            #if in_swat_version == 'swatplus':
            #    in_project = 'https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/project.zip'
            #elif in_swat_version == 'swat2012':
            #    in_project = 'https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/swat2012_sampledata.zip'

        if in_parameter_cal is None:
            #raise ProcessorExecuteError('Missing parameter: par_cal')
            if in_swat_version == 'swatplus':
                #in_parameter_cal = 'https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_inputs/par_cal.json'
                raise ProcessorExecuteError('Missing parameter: par_cal')
            elif in_swat_version == 'swat2012':
                in_parameter_cal = None

        if in_swat_file is None:
            #in_swat_file = 'channel_sd_day'
            raise ProcessorExecuteError('Missing parameter: file')

        if in_variable is None:
            #in_variable = 'flo_out,water_temp'
            raise ProcessorExecuteError('Missing parameter: variable')

        if in_unit is None:
            #in_unit = 1
            raise ProcessorExecuteError('Missing parameter: unit')

        if in_start_date is None:
            #in_start_date = 20160101
            raise ProcessorExecuteError('Missing parameter: start_date')

        if in_end_date is None:
            #in_end_date = 20160228
            raise ProcessorExecuteError('Missing parameter: end_date')

        if in_skip_years is None:
            #in_skip_years = 2
            raise ProcessorExecuteError('Missing parameter: skip_years')


        #################################
        ### Input and output          ###
        ### storage/download location ###
        #################################

        # Where to store output data
        output_dir = f'{self.download_dir}/out/{self.process_id}/job_{self.job_id}'
        output_url = f'{self.download_url}/out/{self.process_id}/job_{self.job_id}'
        os.makedirs(output_dir, exist_ok=True)
        LOGGER.debug(f'All results will be stored     in: {output_dir}')
        LOGGER.debug(f'All results will be accessible in: {output_url}')
        downloadlink1 = f'{output_url}/inputs.sqlite'
        downloadlink2 = f'{output_url}/thread_1.sqlite'


        ############################
        ### Run docker container ###
        ############################

        if in_parameter_cal is None:
            in_parameter_cal = "NULL"

        # Assemble those args that will be passed to the script:
        # This is the path thath the program inside the docker will use
        # to store the output files, "inputs.sqlite" and "thread_1.sqlite",
        # so it has to correspond to where you mount the output directory to.
        storage_path = '/out'
        script_args = [
            in_swat_version,
            in_project,
            in_parameter_cal,
            in_swat_file,
            in_variable.replace(" ", ""),
            str(in_unit),
            str(in_start_date),
            str(in_end_date),
            str(in_skip_years),
            storage_path
        ]

        # Run the container:
        returncode, stdout, stderr, user_err_msg = run_docker_container(
            self.docker_executable,
            self.image_name,
            self.script_name,
            output_dir,
            self.job_id,
            script_args
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
            response_object = {
                "outputs": {
                    "swat_output_summary": {
                        "title": self.metadata['outputs']['swat_output_summary']['title'],
                        "description": self.metadata['outputs']['swat_output_summary']['description'],
                        "href": downloadlink1
                    },
                    "swat_output_file": {
                        "title": self.metadata['outputs']['swat_output_file']['title'],
                        "description": self.metadata['outputs']['swat_output_file']['description'],
                        "href": downloadlink2
                    }
                }
            }

            LOGGER.debug('Returning results to caller.')
            return 'application/json', response_object


def run_docker_container(
        docker_executable,
        image_name,
        script_name,
        output_dir,
        job_id,
        script_args
    ):

    LOGGER.debug('Will use this image: %s' % image_name)

    # Create container name
    # Note: Only [a-zA-Z0-9][a-zA-Z0-9_.-] are allowed
    #container_name = "%s_%s" % (image_name.split(':')[0], os.urandom(5).hex())
    container_name = "%s_%s" % (image_name.split(':')[0], job_id)
    LOGGER.debug(f'Prepare running docker (image {image_name}, container: {container_name})')


    # Prepare container command

    # Define paths inside the container
    # This has to be the same as the "storage_path" passed to the R script (see above)
    container_out = '/out/'

    # Mount volumes and set command
    docker_command = [
        docker_executable, "run", "--rm", "--name", container_name,
        "-v", f"{output_dir}:{container_out}",
        "-e", f"R_SCRIPT={script_name}",  # Set the R_SCRIPT environment variable
        image_name,
        "--",  # Indicates the end of Docker's internal arguments and the start of the user's arguments
    ]
    docker_command = docker_command + script_args

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
