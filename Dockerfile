# Using the RStudio Verse image
FROM rocker/verse:latest

# Install CRAN packages
RUN Rscript -e "install.packages(c('haven','survey','shiny','sf','FactoMineR','leaflet'), dependencies=TRUE, repos='http://cran.rstudio.com')"
RUN apt-get update && apt-get install -y \
    libudunits2-dev \
    libgdal-dev \
    libproj-dev \
    libgeos-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && apt-get clean

# Expose ports for RStudio Server
EXPOSE 8787

# Create necessary directories
RUN mkdir -p /home/rstudio/LHS0003

# Set the RStudio Server with Supervisor
CMD ["/init"]
