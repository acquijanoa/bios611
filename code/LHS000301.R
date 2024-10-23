##########################################
##
##      UNC LATIN AMERICAN HEALTH STUDIES
## 
## File: LHS000301.R
## 
## Project: Women obesity in Honduras 
##
## Description: Creates the derived dataset that 
##              will be used of the analysis
##
## Programmer: Álvaro Quijano-Angarita
##
## Date: 09/24/2024
## 
############################################

## Uploading libraries
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


### Derive variables in the working project dataset
LHS000301 <- women_hon %>% mutate(
  BMI = case_when(WW8 == 999.8 | WW7 == 999.8 ~ NA,   
                  is.na(WW7) | is.na(WW8) ~ NA,
                  TRUE ~ WW7/(WW8/100)^2),
  OVERWEIGHT = case_when(is.na(BMI) ~ NA,
                         BMI >=25  ~ 1,
                         BMI < 25 ~ 0), 
  WOMEN_AGE_C4 = cut(WB4, breaks = c(15,seq(20,50,by=10)), 
                     right = F, 
                     include.lowest = T),
  WOMEN_AGE_C7 = cut(WB4, breaks = seq(15,50,by=5), 
                     right = F, 
                     include.lowest = T),
  WOMEN_AGE_C6 = cut(WB4, breaks = c(seq(15,40,by=5),50), 
                     right = F, 
                     include.lowest = T),
  REGION = HH7,
  WOMEN_EDUCATION_C4 = case_when(
    welevel == 0 ~ 0,
    welevel %in% c(1,2) ~ 1,
    welevel %in% c(3,4) ~ 2,
    welevel %in% c(5) ~ 3
  ),
  WOMEN_EDUCATION_C3 = case_when(
    welevel %in% c(0,1,2) ~ 0,
    welevel %in% c(3,4) ~ 1,
    welevel %in% c(5) ~ 2
  ),
  URBAN = case_when(HH6 == 1 ~ 1,
                    HH6 == 2 ~ 0,
                    is.na(HH6) ~ NA),
  LITERACY_C2 = case_when(WB14 %in% c(1,2,4) ~ 1,
                        WB14 == 3 ~ 0,
                        TRUE ~ 9),
  DOMAIN = ifelse(is.na(BMI) + is.na(WOMEN_AGE_C7) == 0 & CP1 ==2 ,1,0)) %>% 
  select(PSU,stratum, wmweight, BMI,OVERWEIGHT,WOMEN_AGE_C4, WOMEN_AGE_C7,WOMEN_AGE_C6,DOMAIN,windex5, REGION,
         URBAN, WOMEN_EDUCATION_C4, WOMEN_EDUCATION_C3,MSTATUS,LITERACY_C2,ethnicity)

## Create labels
LHS000301$REGION <- factor(LHS000301$REGION, 
                           levels = 1:20, 
                           labels = c("ATLANTIDA", "COLON", "COMAYAGUA", "COPAN", 
                                      "CORTES", "CHOLUTECA", "EL PARAISO", 
                                      "FRANCISCO MORAZAN", "GRACIAS A DIOS", "INTIBUCA", 
                                      "ISLAS DE LA BAHIA", "LA PAZ", "LEMPIRA", 
                                      "OCOTEPEQUE", "OLANCHO", "SANTA BARBARA", 
                                      "VALLE", "YORO", "SAN PEDRO SULA", "DISTRITO CENTRAL"))
LHS000301$URBAN <- factor(LHS000301$URBAN, 
                            levels = 0:1,
                            labels=c("Rural","Urban"))

LHS000301$WOMEN_EDUCATION_C4 <- factor(LHS000301$WOMEN_EDUCATION_C4, 
                                       levels = 0:3,
                                       labels=c("No education",
                                                     "Primary",
                                                     "Secondary/Highschool",
                                                     "Higher education"))

LHS000301$WOMEN_EDUCATION_C3 <- factor(LHS000301$WOMEN_EDUCATION_C3, 
                                        levels = 0:2,
                                        labels=c("No education/Primary",
                                                  "Secondary/Highschool",
                                                  "Higher education"))

LHS000301$windex5 <- factor(LHS000301$windex5, 
                              levels = 1:5,
                              labels=c("Poorest",
                                        "Poorer",
                                        "Middle",
                                        "Richer",
                                        "Richest"))

LHS000301$LITERACY_C2 <- factor(LHS000301$LITERACY_C2, 
                                  levels =c(0,1,9), 
                                  labels=c("Cannot read",
                                           "Can read","Missing"))

### Saving the file in Rdata format
save(LHS000301, file="../derived_data/LHS000301.Rdata")

table(LHS000301$LITERACY_C2, LHS000301$WOMEN_EDUCATION_C3, useNA = "always")
