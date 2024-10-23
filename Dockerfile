# Using the Rstudio verse image
FROM rocker/verse:latest

# Installing CRAN packages
RUN Rscript -e "install.packages(c('haven','survey','rtf'), dependencies=TRUE, repos='http://cran.rstudio.com/')"

## Using port 8787
EXPOSE 8787

## Creating the directory in the container 
RUN mkdir -p home/rstudio/LHS000301

# Setting the Rstudio server
CMD ["/init"]
