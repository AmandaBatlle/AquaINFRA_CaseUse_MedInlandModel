# Pygeoapi processes HOWTO

These are some how-tos mainly as reference to ourselves... Frequently needed commands.

## Quickly update process

On the server, go to the directory containing the repo and pull the newest changes from GitHub:

```
# Go to the directory:
cd /opt/.../pygeoapi/pygeoapi/process/AquaINFRA_CaseUse_MedInlandModel

# Make sure you are on the correct branch:
git status # possibly git stash...
git checkout main

# Pull changes
git pull
```

If something inside the Docker image changed, re-build the docker image:

```
# image name must correspond to the name hard-coded in the process file:
docker build -t catalunya-tordera-image .

# add another tag to the image that keeps the current date:
today=$(date '+%Y%m%d')
docker build -t catalunya-tordera-image:${today} .

```

If something outside the Docker image also changed, re-install the changes on pygeoapi:

```
# activate virtual environment:
cd /opt/.../pygeoapi
source ../venv3/bin/activate

# install changes:
pip install .

# restart pygeoapi:
sudo systemctl restart pygeoapi
```