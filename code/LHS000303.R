##########################################
##
##      UNC LATIN AMERICAN HEALTH STUDIES
## 
## File: LHS000303.R
## 
## Project: Women's overweight/obesity in Honduras
##
## Description: Estimates the prevalence of
##          women's overweight/obesity by selected variables
##          and creates RTF file 
## 
## Programmer: Álvaro Quijano
##
## Date: 09/24/2024
## 
############################################

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

## loading the data
load("../derived_data/LHS000301.Rdata")

## Uploading libraries
library(haven)
library(dplyr)
library(survey)
library(rtf)

## We create the design
hond_design = survey::svydesign(ids=~PSU, 
                                strata=~stratum,
                                weights=~wmweight, 
                                data = LHS000301)

### Creating a subset of observations
hond_design_sub = subset(hond_design, DOMAIN==1)

#####------------------------------------------------------------------
##### Estimates prevalence using the logistic model with log-link
#####------------------------------------------------------------------

### overweight/obesity ~  age
mod_age <-  svyglm(formula = OVERWEIGHT ~ -1 + WOMEN_AGE_C4 , design = hond_design_sub, 
                 family = quasibinomial(link="log"))
age.db <- data.frame(`Variable`= "Women's Age", `Level`=gsub(x = names(exp(coefficients(mod_age))),
                                    pattern = "WOMEN_AGE_C4",
                                    replacement = "") ,
              `Prevalence`=round(exp(coefficients(mod_age)),4))

### overweight/obesity ~  wealth
mod_wealth <-  svyglm(formula = OVERWEIGHT ~ -1 + windex5 , design = hond_design_sub, 
                    family = quasibinomial(link="log"))
wealth.db <- data.frame(`Variable`="Wealth status", `Level`=gsub(x =names(exp(coefficients(mod_wealth))),
                                                                    pattern = "windex5",
                                                                    replacement = ""),
                     `Prevalence`= round(exp(coefficients(mod_wealth)),4))
### overweight/obesity ~  urban
mod_urban <-  svyglm(formula = OVERWEIGHT ~ -1 + URBAN, design = hond_design_sub,
                   family = quasibinomial(link="log")); summary(mod_urban)
urban.db <- data.frame(`Variable`="Area",`Level`=  gsub(x =names(exp(coefficients(mod_urban))),
                                                             pattern="URBAN",
                                                             replacement = ""),
                       `Prevalence`= round(exp(coefficients(mod_urban)),4))

### overweight/obesity ~  region
mod_region <-  svyglm(formula = OVERWEIGHT ~-1 + REGION, design = hond_design_sub, 
                    family = quasibinomial(link="log"))
region.db <- data.frame(`Variable`="Region",`Level`= stringr::str_to_title(gsub(x = names(exp(coefficients(mod_region))),
                                        pattern = "REGION",
                                        replacement = "")),
                       `Prevalence`= round(exp(coefficients(mod_region)),4))

### overweight/obesity ~  women education 
mod_education <- svyglm(formula = OVERWEIGHT ~ -1 + WOMEN_EDUCATION_C3, design = hond_design_sub, 
                       family = quasibinomial(link="log"))
education.db <- data.frame(`Variable`="Education",`Level`= gsub(x =names(exp(coefficients(mod_education))),
                                            pattern="WOMEN_EDUCATION_C3",
                                            replacement = ""),
                           `Prevalence`= round(exp(coefficients(mod_education)),4))


### Write the RTF file
rtf_file <- RTF(paste0("../output/prevalences_",format(Sys.Date(), "%b%y"),".rtf"))

# Add the dataframe as a table
addHeader(rtf_file, "Women's overweight and obesity prevalences")
addNewLine(rtf_file, 1)
addTable(rtf_file, age.db)
addNewLine(rtf_file, 1)
addTable(rtf_file, wealth.db)
addNewLine(rtf_file, 1)
addTable(rtf_file, urban.db)
addNewLine(rtf_file, 1)
addTable(rtf_file, region.db)
addNewLine(rtf_file, 1)
addTable(rtf_file, education.db)
addNewLine(rtf_file, 1)
done(rtf_file)


###-------------------------------------------------------------------------------
###  Estimates predicted risk of overwight/obesity by REGION and wealth status
###-------------------------------------------------------------------------------
## mod_region_windex = svyglm(formula = OVERWEIGHT ~ factor(REGION) +  
##                                    factor(windex5), design = hond_design_sub, 
##                     family = quasibinomial(link="logit"))


### Creating the dataset with predicted values
## db_pred = LHS000301 %>% filter(DOMAIN==1)
## db_pred$prob_overweight =  predict(mod_region_windex, type="response")
## db_pred %<>%  select(REGION,windex5, prob_overweight) %>% distinct()

## save(db_pred, file = "LHS00302.Rdata")

