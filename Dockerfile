# Using the Rstudio verse image
FROM rocker/verse:latest

# Installing CRAN packages
RUN Rscript -e "install.packages(c('haven'), dependencies=TRUE, repos='http://cran.rstudio.com/')"

## Using port 8787
EXPOSE 8787

## Creating the directory in the container 
RUN mkdir -p home/rstudio/BIOS611_docker

# Setting the Rstudio server
CMD ["/init"]
