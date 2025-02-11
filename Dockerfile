FROM rocker/r-ver:4.3.0

# Install remotes (needed to install specific versions of packages)
RUN R -e "install.packages('remotes', repos='https://cran.rstudio.com/')"

# Install SWAT model and make executable:
COPY swat /swat
RUN chmod +x /swat/Scenario_Gloria_linux/rev688_64rel_linux

# Install dependencies
#COPY /.binder/install.R /src/install.R
#RUN Rscript /src/install.R
RUN Rscript -e "install.packages('remotes')"
RUN Rscript -e "install.packages('dplyr')"
RUN Rscript -e "install.packages(c('remotes', 'devtools', 'data.table'), repos='https://cran.rstudio.com/')"
#RUN Rscript -e "remotes::install_github('chrisschuerz/SWATrunR')"
RUN Rscript -e "remotes::install_github('chrisschuerz/SWATrunR', dependencies=TRUE, upgrade='never')"

# Get the actual script:
COPY src /src

# It has to be run where the executables can be found:
WORKDIR /swat

# Use sh -c to expand the environment variables and pass arguments
ENTRYPOINT ["sh", "-c", "Rscript /src/${R_SCRIPT} $@"]
