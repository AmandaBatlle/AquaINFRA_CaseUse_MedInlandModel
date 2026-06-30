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

# for debugging build issues:
#docker build --no-cache --progress=plain -t catalunya-tordera-image .

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

## Quickly add process

To add a new process, of course it needs to be in the repo and the Dockerfile needs to be built etc.

Plus:

Make sure the config.json contains everything we need:

```
vi /opt/.../pygeoapi/config.json
```

Add the new process(es) to `pygeoapi-config.yml` and `plugin.py`:

```
vi /opt/.../pygeoapi/pygeoapi-config.yml
vi /opt/.../pygeoapi/pygeoapi/plugin.py"

```

Install added process, so that pygeoapi can import them:

```
# activate virtual environment:
cd /opt/.../pygeoapi
source ../venv3/bin/activate

# install changes:
pip install .
```

Generate a new `pygeoapi-openapi.yml` (after pip installing! virtual env must be active!)

```
export PYGEOAPI_CONFIG=pygeoapi-config.yml
export PYGEOAPI_OPENAPI=pygeoapi-openapi.yml
date; pygeoapi openapi generate $PYGEOAPI_CONFIG --output-file $PYGEOAPI_OPENAPI

```


Then restart pygeoapi:

```
# restart pygeoapi:
sudo systemctl restart pygeoapi
```