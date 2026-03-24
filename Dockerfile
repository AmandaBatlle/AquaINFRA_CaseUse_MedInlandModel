FROM rocker/r-ver:4.3.0

RUN apt-get update && apt-get install -y curl

RUN curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o miniconda.sh \
    && bash miniconda.sh -b -p /opt/conda \
    && rm miniconda.sh \
    && /opt/conda/bin/conda init \
    && ln -s /opt/conda/bin/conda /usr/local/bin/conda \
    && ln -s /opt/conda/bin/activate /usr/local/bin/activate

COPY .binder/environment.yml /tmp/environment.yml

# to avoid build error 2026-03-17
RUN conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r

RUN conda env create -f /tmp/environment.yml

RUN conda run -n r-environment Rscript -e "\
if (!requireNamespace('remotes', quietly = TRUE)) install.packages(c('remotes', 'data.table'), repos='https://cran.rstudio.com/'); \
remotes::install_version('readr', version = '2.1.4', repos = 'https://cran.rstudio.com/', dependencies = TRUE, upgrade = 'never')"

RUN conda run -n r-environment Rscript -e "packageVersion('readr')"

RUN conda run -n r-environment Rscript -e "if (!requireNamespace('SWATrunR', quietly = TRUE)) remotes::install_github('chrisschuerz/SWATrunR')"

COPY swat /swat
RUN chmod +x /swat/Scenario_Gloria_linux/rev60.5.7_64rel_linux

COPY src /src
WORKDIR /src

ENTRYPOINT ["conda", "run", "-n", "r-environment", "/bin/bash", "-c", "Rscript /src/${R_SCRIPT} $@"]

# Example build command:
# This includes the git commit hash, so please
# make sure all your changes are committed/stashed:
# today=$(date '+%Y%m%d')
# githash=$(git rev-parse --short HEAD)
# docker build \
#   --build-arg GIT_COMMIT=${githash} \
#   -t catalunya-tordera:${today}-${githash} .
