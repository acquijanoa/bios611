##########################################
##
##      UNC LATIN AMERICAN HEALTH STUDIES
## 
## File: LHS000302.R
## 
## Project: Women's overweight/obesity in Honduras
##
## Description: Creates a report to evaluate the missingness
##              in the dataset
## 
## Programmer: Álvaro Quijano
##
## Date: 10/OCT/24
## 
############################################

## Load libraries
library(tidyverse)
library(haven)
library(rtf)

# Function to get the directory of the source file
this_file <- function() {
  cmdArgs <- commandArgs(trailingOnly = FALSE)
  match <- grep("--file=", cmdArgs)
  
  if (length(match) > 0) {
    # When running with Rscript or other command line interface
    normalizePath(sub("--file=", "", cmdArgs[match]))
  } else if (!is.null(sys.frames()[[1]]$ofile)) {
    # When running interactively (e.g., using source())
    normalizePath(sys.frames()[[1]]$ofile)
  } else {
    stop("Cannot determine the source file location.")
  }
}

### Code to define the working directory in case we are in console or in the rstudio
if (interactive()) {
  library(rstudioapi)
  setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
} else {
  setwd(dirname(this_file()))
}
# Setting the working directory to the location of the files

### Load data
women_hon <- read_sav("../data/wm.sav") %>%
  mutate(across(where(is.character), ~ na_if(., "")))

### Function to evaluate the percentage of missing values
missingness <- function(db,var){ 
  nmiss = sum(is.na(db %>% pull({{var}}))) 
  total = dim(db)[1]
  round(100*nmiss/total, 2)
}

### Extract the labels from the original dataset
variable_labels_wm <- lapply(women_hon, function(x) attr(x, "label"))
db_labels_wm <- data.frame(variable = names(variable_labels_wm), 
                           label = unlist(paste(variable_labels_wm,1:597)),
                           missing = map_dbl(names(variable_labels_wm), ~ missingness(women_hon, .x)),
                           stringsAsFactors = FALSE) %>% 
  arrange(missing,variable)

### Write the RTF file
rtf_missing <- rtf::RTF(paste0("../output/missing_",format(Sys.Date(), "%b%y"),".rtf"), 
                        height = 11, 
                        width = 8.5, 
                        font.size = 8)
rtf::addHeader(rtf_missing,paste0("Women's DHS missing evaluation (Total rows= ",dim(women_hon)[1],")"), 
               font.size = 10)
rtf::addNewLine(rtf_missing, 1)
colnames(db_labels_wm) = c("Variable name","Variable label","% missing values")
rtf::addTable(rtf_missing, db_labels_wm, col.widths=c(1,4,1.5))
rtf::done(rtf_missing)

