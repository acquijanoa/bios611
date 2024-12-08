##########################################
##
##      UNC LATIN AMERICAN HEALTH STUDIES
## 
## File: LHS000304.R
## 
## Project: Women's overweight/obesity in Honduras
##
## Description: Produce the maps 
## 
## Programmer: Álvaro Quijano
##
## Date: 12/06/2024
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
library(dplyr)
library(survey)
library(gridExtra)
library(ggplot2)

## We create the design
hond_design = survey::svydesign(ids=~PSU, 
                                strata=~stratum,
                                weights=~wmweight, 
                                data = LHS000301)

### Creating a subset of observations
hond_design_sub = subset(hond_design, DOMAIN==1)

### Run the function 
replace_tildes <- function(text) {
  # Define a vector of patterns and replacements
  patterns <- c("á", "é", "í", "ó", "ú", "ü", "ñ", "Á", "É", "Í", "Ó", "Ú", "Ü", "Ñ")
  replacements <- c("a", "e", "i", "o", "u", "u", "n", "A", "E", "I", "O", "U", "U", "N")
  
  # Use gsub with a loop to replace each pattern with its corresponding replacement
  for (i in 1:length(patterns)) {
    text <- gsub(patterns[i], replacements[i], text, fixed = TRUE)
  }
  return(text)
}
generate_plot = function(db, title, out, var){
  p1 <- ggplot(db) + 
    geom_sf(data = shp_wd, inherit.aes = F, alpha = 0.9) +
    geom_sf(aes(fill = prob_overweight), color = "black")  +
    geom_sf(data = shp_bdr, inherit.aes = F, fill = NA, lwd = 0.6, color = "black") +
    facet_wrap(as.formula(paste("~", var)), ncol=3) +
    ylim(c(12.8,16.4)) + 
    xlim(c(-90.05,-83)) +
    scale_fill_gradient2(
      low = "yellow",
      mid = "#FFDBBB",
      high = "red", 
      midpoint = .5
    ) + 
    theme_bw() + 
    theme(panel.background = element_rect(fill = "aliceblue"), 
          title = element_text(size = 12, face = "bold"),
          legend.position = "bottom", 
          axis.text.x = element_text(size = 6, angle = 0, vjust = 0.5),
          axis.text.y = element_text(size = 6)) + 
    guides(fill = guide_legend(nrow = 1)) + 
    labs(title = title, 
         fill = "Probability", x = "", y = "")
  
  p1
  ### Maps
  ggsave(p1, file=paste0("../Output/",out,".png"), device = "png", dpi = 200, 
                width = 8.5, height = 11, units = "in")
}

## Loading the shapefile
shp_mg = sf::read_sf(paste0("..","/Data/shps/Shp_mgd.shp")) %>% 
  mutate(DHSREGEN = replace_tildes(DHSREGEN), DHSREGSP = replace_tildes(DHSREGSP) ) %>% 
  filter(CNTRYNAMEE == "Honduras")
shp_wd = sf::read_sf(paste0("..","/Data/shps/World_Countries_Generalized.shp")) %>% filter(FID %in% c(23,69,160,56,144))
shp_bdr = sf::read_sf(paste0("..","/Data/shps/borders_.shp"))

### Editing the shapefile
shp_mg$DHSREGEN = toupper(shp_mg$DHSREGEN)
shp_mg = shp_mg %>% mutate(DHSREGEN = ifelse(DHSREGEN == "RESTO FRANCISCO MORAZAN","FRANCISCO MORAZAN",DHSREGEN))
shp_mg = shp_mg %>% mutate(DHSREGEN = ifelse(DHSREGEN == "RESTO CORTES","CORTES",DHSREGEN))

###-------------------------------------------------------------------------------
###  Estimates predicted risk of overwight/obesity by REGION and wealth status
###-------------------------------------------------------------------------------
mod_map1 = svyglm(formula = OVERWEIGHT ~ factor(REGION) + factor(windex5), design = hond_design_sub, 
                  family = quasibinomial(link="logit"))


### Creating the dataset with predicted values
db_pred = LHS000301 %>% filter(DOMAIN==1)
db_pred$prob_overweight =  predict(mod_map1, type="response")
db_pred = db_pred %>% select(REGION,windex5, prob_overweight) %>% distinct() %>% 
            mutate(prob_overweight=as.numeric(prob_overweight))

### Full join with DHS data
shp_st_mgd1 = shp_mg %>% full_join(db_pred %>% 
                                    rename(DHSREGEN = REGION), by = "DHSREGEN") 
generate_plot(db=shp_st_mgd1, 
              title = "Probability of Women Overweight and Obesity in Honduras by Wealth Status, 2019",
              out = "map_wealth",
              var = "windex5")


###-------------------------------------------------------------------------------
###  Estimates predicted risk of overwight/obesity by REGION and women_Age
###-------------------------------------------------------------------------------
mod_map2 = svyglm(formula = OVERWEIGHT ~ factor(REGION) + factor(WOMEN_AGE_C4), design = hond_design_sub, 
                  family = quasibinomial(link="logit"))


### Creating the dataset with predicted values
db_pred2 = LHS000301 %>% filter(DOMAIN==1)
db_pred2$prob_overweight =  predict(mod_map2, type="response")
db_pred2 = db_pred2 %>% select(REGION,WOMEN_AGE_C4, prob_overweight) %>% distinct() %>% 
              mutate(prob_overweight = as.numeric(prob_overweight))

### Full join with DHS data
shp_st_mgd2 = shp_mg %>% full_join(db_pred2 %>% 
                                    rename(DHSREGEN = REGION), by = "DHSREGEN") 
generate_plot(db=shp_st_mgd2, 
              title = "Probability of Women Overweight and Obesity in Honduras by women age, 2019",
              out = "map_age",
              var = "WOMEN_AGE_C4")

###-------------------------------------------------------------------------------
###  Estimates predicted risk of overwight/obesity by REGION and women_Age
###-------------------------------------------------------------------------------
mod_map2 = svyglm(formula = OVERWEIGHT ~ factor(REGION) + factor(WOMEN_AGE_C4), design = hond_design_sub, 
                  family = quasibinomial(link="logit"))


### Creating the dataset with predicted values
db_pred2 = LHS000301 %>% filter(DOMAIN==1)
db_pred2$prob_overweight =  predict(mod_map2, type="response")
db_pred2 = db_pred2 %>% select(REGION,WOMEN_AGE_C4, prob_overweight) %>% distinct() %>% 
  mutate(prob_overweight = as.numeric(prob_overweight))

### Full join with DHS data
shp_st_mgd2 = shp_mg %>% full_join(db_pred2 %>% 
                                     rename(DHSREGEN = REGION), by = "DHSREGEN") 
generate_plot(db=shp_st_mgd2, 
              title = "Probability of Women Overweight and Obesity in Honduras by women`s age, 2019",
              out = "map_age",
              var = "WOMEN_AGE_C4")

###-------------------------------------------------------------------------------
###  Estimates predicted risk of overwight/obesity by REGION and Women education
###-------------------------------------------------------------------------------
mod_map3 = svyglm(formula = OVERWEIGHT ~ factor(REGION) + factor(WOMEN_EDUCATION_C3), design = hond_design_sub, 
                  family = quasibinomial(link="logit"))

### Creating the dataset with predicted values
db_pred3 = LHS000301 %>% filter(DOMAIN==1)
db_pred3$prob_overweight =  predict(mod_map3, type="response")
db_pred3 = db_pred3 %>% select(REGION,WOMEN_EDUCATION_C3, prob_overweight) %>% distinct() %>% 
  mutate(prob_overweight = as.numeric(prob_overweight))

### Full join with DHS data
shp_st_mgd3 = shp_mg %>% full_join(db_pred3 %>% 
                                     rename(DHSREGEN = REGION), by = "DHSREGEN") 
generate_plot(db=shp_st_mgd3, 
              title = "Probability of Women Overweight and Obesity in Honduras by women`s education, 2019",
              out = "map_educ",
              var = "WOMEN_EDUCATION_C3")

###-------------------------------------------------------------------------------
###  Estimates predicted risk of overwight/obesity by REGION and URBAN/RURAL
###-------------------------------------------------------------------------------
mod_map4 = svyglm(formula = OVERWEIGHT ~ factor(REGION) + factor(URBAN), design = hond_design_sub, 
                  family = quasibinomial(link="logit"))

### Creating the dataset with predicted values
db_pred4 = LHS000301 %>% filter(DOMAIN==1)
db_pred4$prob_overweight =  predict(mod_map4, type="response")
db_pred4 = db_pred4 %>% select(REGION,URBAN, prob_overweight) %>% distinct() %>% 
  mutate(prob_overweight = as.numeric(prob_overweight))

### Full join with DHS data
shp_st_mgd4 = shp_mg %>% full_join(db_pred4 %>% 
                                     rename(DHSREGEN = REGION), by = "DHSREGEN") 
generate_plot(db=shp_st_mgd4, 
              title = "Probability of Women Overweight and Obesity in Honduras by women`s education, 2019",
              out = "map_urban",
              var = "URBAN")



