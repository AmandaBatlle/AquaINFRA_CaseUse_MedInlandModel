FROM rocker/r-ver:4.3.0

RUN apt-get update && apt-get install -y curl

RUN curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o miniconda.sh \
    && bash miniconda.sh -b -p /opt/conda \
    && rm miniconda.sh \
    && /opt/conda/bin/conda init \
    && ln -s /opt/conda/bin/conda /usr/local/bin/conda \
    && ln -s /opt/conda/bin/activate /usr/local/bin/activate

COPY .binder/environment.yml /tmp/environment.yml
RUN conda env create -f /tmp/environment.yml

RUN conda run -n r-environment Rscript -e "if (!requireNamespace('remotes', quietly = TRUE)) install.packages('remotes', repos='https://cran.rstudio.com/')"
RUN conda run -n r-environment Rscript -e "if (!requireNamespace('SWATrunR', quietly = TRUE)) remotes::install_github('chrisschuerz/SWATrunR')"

COPY swat /swat
RUN chmod +x /swat/swatplus_rev60_demo/rev60.5.7_64rel_linux

COPY src /src
WORKDIR /src

ENTRYPOINT ["conda", "run", "-n", "r-environment", "/bin/bash", "-c", "Rscript /src/${R_SCRIPT} $@"]