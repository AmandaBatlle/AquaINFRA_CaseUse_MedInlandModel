FROM rocker/r-ver:4.3.0

RUN apt-get update && apt-get install -y \
    curl

RUN curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o miniconda.sh \
    && bash miniconda.sh -b -p /opt/conda \
    && rm miniconda.sh \
    && /opt/conda/bin/conda init \
    && ln -s /opt/conda/bin/conda /usr/local/bin/conda \
    && ln -s /opt/conda/bin/activate /usr/local/bin/activate

# Install SWAT model and make executable:
COPY swat /swat
RUN chmod +x /swat/swatplus_rev60_demo/rev60.5.7_64rel_linux

WORKDIR /src

COPY /.binder/environment.yml /src/environment.yml
RUN conda env create -f /src/environment.yml

RUN Rscript -e "install.packages('remotes', repos='https://cran.rstudio.com/')"
#RUN Rscript -e "if (!requireNamespace('SWATrunR', quietly = TRUE)) remotes::install_github('chrisschuerz/SWATrunR')"

# Get the actual script:
COPY src /src

# It has to be run where the executables can be found:
#WORKDIR /swat

ENTRYPOINT ["conda", "run", "-n", "r-environment", "/bin/bash", "-c", "Rscript /src/${R_SCRIPT} $@"]
