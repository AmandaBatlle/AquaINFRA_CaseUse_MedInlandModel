import logging
import subprocess
import json
import os
from pathlib import Path
from pygeoapi.process.base import BaseProcessor, ProcessorExecuteError

'''
How to call this process:

# TESTED 2026-04-02: FAILS.
# DOES NOT WORK YET, script "swat_mitgcm_connection.R" missing!
curl -i -X POST https://${PYSERVER}/processes/swat-marine-connection/execution \
  --header "Content-Type: application/json" \
  --data '{
  "inputs": {
        "swat_output_file": "https://raw.githubusercontent.com/AmandaBatlle/AquaINFRA_CaseUse_MedInlandModel/refs/heads/main/example_results/thread_1.sqlite"
    }
}'

'''

LOGGER = logging.getLogger(__name__)

script_title_and_path = __file__
metadata_title_and_path = script_title_and_path.replace('.py', '.json')
PROCESS_METADATA = json.load(open(metadata_title_and_path))

class SwatMarineConnectionProcessor(BaseProcessor):

    def __init__(self, processor_def):
        super().__init__(processor_def, PROCESS_METADATA)
        self.supports_outputs = True
        self.job_id = 'nothing-yet'
        self.process_id = self.metadata["id"]
        self.image_name = 'catalunya-tordera:20260608-1eccf57'
        self.script_name = 'swat_mitgcm_connection.R'
        config_file_path = os.environ.get('AQUAINFRA_CONFIG_FILE', "./config.json")
        with open(config_file_path, 'r') as config_file:
            config = json.load(config_file)
            self.download_dir = config["download_dir"].rstrip('/')
            self.download_url = config["download_url"].rstrip('/')
            self.docker_executable = config.get("docker_executable", "docker")

    def set_job_id(self, job_id: str):
        self.job_id = job_id

    def __repr__(self):
        return f'<SwatMarineConnectionProcessor> {self.name}'

    def execute(self, data, outputs=None):

        #################################
        ### Get user inputs and check ###
        #################################

        # Get user inputs
        in_file1 = data.get('swat_output_file')

        # Check
        if in_file1 is None:
            raise ProcessorExecuteError('Missing parameter "swat_output_file". Please provide a value.')

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
        #downloadlink1 = f'{output_url}/inputs.sqlite'
        #downloadlink2 = f'{output_url}/thread_1.sqlite'
        downloadfilename = 'joinedFile-%s.txt' % self.job_id
        #downloadlink = self.download_url.rstrip('/')+os.sep+"out"+os.sep+downloadfilename
        downloadlink = f'{output_url}/{downloadfilename}'


        ############################
        ### Run docker container ###
        ############################

        returncode, stdout, stderr = run_docker_container(
            self.docker_executable,
            self.image_name,
            self.script_name,
            output_dir,
            self.job_id,
            in_file1,
            downloadfilename
        )

        # print R stderr/stdout to debug log:
        for line in stdout.split("\n"):
            if not len(line.strip()) == 0:
                LOGGER.debug('R stdout: %s' % line)

        for line in stderr.split("\n"):
            if not len(line.strip()) == 0:
                LOGGER.debug('R stderr: %s' % line)

        if not returncode == 0:
            very_debug = True # TODO: This is only a temporary solution!
            if very_debug:
                # TODO: This prints all the content to the response. Remove this after debug period!
                err_msg = 'Running docker container failed. Stderr: ' + ' - '.join(stderr.split('\n'))
            else:
                err_msg = 'Running docker container failed.'
                for line in stderr.split('\n'):
                    if line.startswith('Error'): # TODO: Sometimes error messages span several lines.
                        err_msg = 'Running docker container failed: %s' % (line)
            raise ProcessorExecuteError(user_msg = err_msg)

        else:
            response_object = {
                "outputs": {
                    "joined_file": {
                        "title": self.metadata['outputs']['output_file']['title'],
                        "description": self.metadata['outputs']['output_file']['description'],
                        "href": downloadlink
                    }
                }
            }

            return 'application/json', response_object

def run_docker_container(
        docker_executable,
        image_name,
        script_name,
        output_dir,
        job_id,
        in_file1,
        outputFilename
    ):

    LOGGER.debug('Will use this image: %s' % image_name)

    # Create container name
    # Note: Only [a-zA-Z0-9][a-zA-Z0-9_.-] are allowed
    #container_name = "%s_%s" % (image_name.split(':')[0], os.urandom(5).hex())
    container_name = "%s_%s" % (image_name.split(':')[0], job_id)
    LOGGER.debug(f'Prepare running docker (image {image_name}, container: {container_name})')

    # Define paths inside the container
    container_out = '/out'

    # Mount volumes and set command
    docker_command = [
        docker_executable, "run", "--rm", "--name", container_name,
        "-v", f"{output_dir}:{container_out}",
        "-e", f"R_SCRIPT={script_name}",  # Set the R_SCRIPT environment variable
        image_name,
        "--",  # Indicates the end of Docker's internal arguments and the start of the user's arguments
        in_file1,
        f"{container_out}/{outputFilename}"
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
        return result.returncode, stdout, stderr

    except subprocess.CalledProcessError as e:
        LOGGER.debug('Failed running docker container')
        return e.returncode, e.stdout.decode(), e.stderr.decode()
