##########################################
##
##      UNC LATIN AMERICAN HEALTH STUDIES
## 
## File: LHS000301.R
## 
## Project: Women obesity in Honduras 
##
## Description: 
##
## Programmer: Álvaro Quijano
##
## Date: 09/24/2024
## 
############################################

## Uploading libraries
library(tidyverse)
library(haven)

# Get the directory of the source file
this_file <- function() {
  cmdArgs <- commandArgs(trailingOnly = FALSE)
  match <- grep("--file=", cmdArgs)
  if (length(match) > 0) {
    # When running with Rscript or other command line interface
    normalizePath(sub("--file=", "", cmdArgs[match]))
  } else if (!is.null(sys.frame(1))) {
    # When running interactively (e.g., using source())
    normalizePath(sys.frame(1)$ofile)
  } else {
    stop("Cannot determine source file location.")
  }
}

setwd(dirname(this_file()))

### Load data
women_hon <- read_sav("../data/wm.sav") 

### Extract the labels from the original dataset
variable_labels_wm <- lapply(women_hon, function(x) attr(x, "label"))
db_labels_wm <- data.frame(variable = names(variable_labels_wm), 
                           label = unlist(paste(variable_labels_wm,1:597) ), 
                           stringsAsFactors = FALSE)
db_labels_wm %>% View()


### Derive variables in the output dataset
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
  DOMAIN = ifelse(is.na(BMI) + is.na(WOMEN_AGE_C7) == 0 & CP1 ==2 ,1,0)) %>% 
  select(PSU,stratum, wmweight, BMI,OVERWEIGHT,WOMEN_AGE_C4, WOMEN_AGE_C7,WOMEN_AGE_C6,DOMAIN,windex5, REGION,
         URBAN, WOMEN_EDUCATION_C4, WOMEN_EDUCATION_C3,MSTATUS,ethnicity)

## Create labels
LHS000301$REGION <- factor(LHS000301$REGION, 
                           levels = 1:20, 
                           labels = c("ATLANTIDA", "COLON", "COMAYAGUA", "COPAN", 
                                      "CORTES", "CHOLUTECA", "EL PARAISO", 
                                      "FRANCISCO MORAZAN", "GRACIAS A DIOS", "INTIBUCA", 
                                      "ISLAS DE LA BAHIA", "LA PAZ", "LEMPIRA", 
                                      "OCOTEPEQUE", "OLANCHO", "SANTA BARBARA", 
                                      "VALLE", "YORO", "SAN PEDRO SULA", "DISTRITO CENTRAL"))
LHS000301$URBAN <- factor(LHS000301$URBAN, levels = 0:1,labels=c("Rural","Urban"))
LHS000301$WOMEN_EDUCATION_C4 <- factor(LHS000301$WOMEN_EDUCATION_C4, levels = 0:3,labels=c("No education",
                                                                                           "Primary",
                                                                                           "Secondary/Highschool",
                                                                                           "Higher education"))
LHS000301$WOMEN_EDUCATION_C3 <- factor(LHS000301$WOMEN_EDUCATION_C3, levels = 0:2,labels=c("No education/Primary",
                                                                                           "Secondary/Highschool","Higher education"))
LHS000301$windex5 <- factor(LHS000301$windex5, levels = 1:5,labels=c("Poorest","Poorer","Middle","Richer","Richest"))

### Saving the file in Rdata format
save(LHS000301, file="../derived_data/LHS000301.Rdata")



