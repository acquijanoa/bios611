# Base image for Shiny
FROM rocker/shiny:latest

# Install system dependencies for sf
RUN apt-get update && apt-get install -y \
    libudunits2-dev \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('sf', 'leaflet','tidyverse','haven','survey','FactoMineR'), repos='https://cloud.r-project.org/')"

# Copy the Shiny app to the image
COPY code/LHS000398 /srv/shiny-server/app

# Set permissions for the Shiny app
RUN chmod -R 755 /srv/shiny-server/app

# Expose the default Shiny port
EXPOSE 3838

# Run the Shiny server
CMD ["/usr/bin/shiny-server"]
