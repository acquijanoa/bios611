library(shiny)
library(tidyverse)
library(survey)
library(DT)
library(sf)
library(leaflet)

# Function to get the directory of the source file

# Load the data
load('~/LHS0003/derived_data/LHS000301.Rdata')

# Get the variables of interest
vars <- c("URBAN",
          "REGION",
          "WOMEN_AGE_C4",
          "WOMEN_AGE_C6",
          "WOMEN_AGE_C7",
          "WOMEN_EDUCATION_C4",
          "WOMEN_EDUCATION_C3",
          "LITERACY_C2","WEALTH_INDEX")


### Doing the PCA analysis
X_pca0 = LHS000301 %>% filter(DOMAIN == 1) %>% 
            select(VT22A, VT22B, VT22C, VT22D, VT22E, VT22F, VT22X) 
X_pca1 = model.matrix(~ -1 + factor(VT22A), data = X_pca0 %>% mutate(VT22A =ifelse(is.na(VT22A),9,VT22A))) 
X_pca2 = model.matrix(~ -1 + factor(VT22B), data = X_pca0 %>% mutate(VT22B =ifelse(is.na(VT22B),9,VT22B))) 
X_pca3 = model.matrix(~ -1 + factor(VT22C), data = X_pca0 %>% mutate(VT22C =ifelse(is.na(VT22C),9,VT22C))) 
X_pca4 = model.matrix(~ -1 + factor(VT22D), data = X_pca0 %>% mutate(VT22D =ifelse(is.na(VT22D),9,VT22D)))  
X_pca5 = model.matrix(~ -1 + factor(VT22E), data = X_pca0 %>% mutate(VT22E =ifelse(is.na(VT22E),9,VT22E))) 
X_pca6 = model.matrix(~ -1 + factor(VT22F), data = X_pca0 %>% mutate(VT22F =ifelse(is.na(VT22F),9,VT22F))) 
X_pca7 = model.matrix(~ -1 + factor(VT22X), data = X_pca0 %>% mutate(VT22X =ifelse(is.na(VT22X),9,VT22X))) 
X_pca = cbind(X_pca1,X_pca2,X_pca3,X_pca4,X_pca5,X_pca6,X_pca7)

### Renaming the Wealth variable
LHS000301 = LHS000301 %>% rename(`WEALTH_INDEX`=windex5)

# Perform PCA
pca_result <- prcomp(X_pca)

# Extract the first 9 PCs
scores <- pca_result$x[, 1:9]

# Calculate weights based on variance explained
weights  <- (pca_result$sdev^2 / sum(pca_result$sdev^2))[1:9]

# Compute the composite score as a weighted sum of the first 9 PCs
composite_score <- rowSums(t(t(scores) * weights))

## Save the composite scores:
LHS000301[LHS000301$DOMAIN == 1,"Discrimination_score"] = composite_score

## Create the survey design
hond_design = survey::svydesign(ids=~PSU, 
                                strata=~stratum,
                                weights=~wmweight, 
                                data = LHS000301)

### Creating a subset of observations
hond_design_sub = subset(hond_design, DOMAIN==1)

### Functions
explain_variable <- function(var) {
  if (var == "URBAN") {
    return("Indicates whether the area is urban or rural.")
  } else if (var == "REGION") {
    return("Represents the geographic region of the respondent.")
  } else if (var == "WOMEN_AGE_C4") {
    return("Categorized age group for women (4 categories).")
  } else if (var == "WOMEN_AGE_C6") {
    return("Categorized age group for women (6 categories).")
  } else if (var == "WOMEN_AGE_C7") {
    return("Categorized age group for women (7 categories).")
  } else if (var == "WOMEN_EDUCATION_C4") {
    return("Categorized level of education for women (4 categories).")
  } else if (var == "WOMEN_EDUCATION_C3") {
    return("Categorized level of education for women (3 categories).")
  } else if (var == "LITERACY_C2") {
    return("Binary indicator of literacy (2 categories).")
  } else {
    return("No explanation available for this variable.")
  }
}

# Define UI for application that draws a histogram
ui <- fluidPage(
  
  # Application title
  titlePanel("Estimating the probability of Women's Overweight/Obesity in Honduras, using DHS data"),
  h3("Final Project - BIOS611"),
  h4("Author: Álvaro Quijano"),
  p("This dashboard provides an analysis of the probability of overweight and obesity among women in Honduras, utilizing data from the Demographic and Health Surveys (DHS, ENDESA in Spanish). The analysis accounts for the complex survey design of the DHS, including stratification, clustering, and sampling weights, ensuring accurate and representative estimates for the population. By integrating statistical models and interactive visualizations, this tool highlights key demographic, socioeconomic, and regional factors associated with women's health outcomes. The dashboard aims to support policymakers, researchers, and public health practitioners in developing targeted interventions to address the growing challenge of overweight and obesity in the region."),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      selectInput(
        inputId = "Vars",
        label = "Variable of interest:",
        choices = vars, 
        multiple = FALSE
      ),
      uiOutput("LevelsUI"),
      radioButtons(
        inputId = "adj_age",
        label = "Adjusted by women's age:",
        choices = list(
          "Age (4 categories)" = "+ WOMEN_AGE_C4",
          "Age (6 categories)" = "+ WOMEN_AGE_C6",
          "Age (7 categories)" = "+ WOMEN_AGE_C7",
          "No" = ""
        ),
        selected = ""),
      radioButtons(
        inputId = "adj_educ",
        label = "Adjusted by women's education:",
        choices = list(
          "Education (3 categories)" = "+ WOMEN_EDUCATION_C3",
          "Education (4 categories)" = "+ WOMEN_EDUCATION_C4",
          "No" = ""
        ),
        selected = ""),
      radioButtons(
        inputId = "adj_disc",
        label = "Adjusted by discrimination experience: ",
        choices = list(
          "Yes" = "+ Discrimination_score",
          "No" = ""
        ),
        selected = ""),
      tags$p(
        style = "font-style: italic ; font-size: 6",  # Apply cursive style
        "Check the 'PCA Analysis' tab to learn about the derivation."
      ),
      radioButtons(
        inputId = "adj_wealth",
        label = "Adjusted by wealth status: ",
        choices = list(
          "Yes" = "+ WEALTH_INDEX",
          "No" = ""
        ),
        selected = "")
    ),
    mainPanel(
      # Show a plot of the generated distribution
      tabsetPanel(
        tabPanel("Data",
                h3("About ENDESA"),
                h4("Encuesta Nacional de Demografía y Salud (ENDESA) 2019"),
                p("The Encuesta Nacional de Demografía y Salud (ENDESA) 2019 is a comprehensive survey conducted in Honduras to provide updated information on key indicators related to health, education, and population trends."),
                p("This initiative, led by the National Institute of Statistics (INE) and the Secretariat of Health (SESAL), also tracks progress toward the Sustainable Development Goals (SDGs) and national plans."),
                p("ENDESA covers diverse topics, including maternal and child health, reproductive health, nutritional trends, early childhood development, and domestic violence. The survey includes data collection through household and individual questionnaires for women, men, and children, alongside measures like anemia tests and water quality assessments."),
                p("For this analysis, we used data exclusively from the women's questionnaire, focusing on women aged 15–49. This allows us to examine health, reproductive, and social indicators specific to this population."),
                p("The full survey and details can be accessed at: ",
                              a("https://ine.gob.hn/v4/endesa/", href = "https://ine.gob.hn/v4/endesa/", target = "_blank"))
        ),
        tabPanel("Probabilities", 
                 h3("Overweight/obseity Probability estimates"),
                 p(textOutput("Vartext")),
                 DTOutput('prev_table'),
        ),
        tabPanel("Model theory",
                 h2("Methodology"),
                 withMathJax(
                   p("To estimate the probability of overweight and obesity among women in Honduras, logistic regression was employed, 
        accommodating the complexities of survey design as described by Lumley (2010). The DHS employs a stratified, 
        multistage cluster sampling design, where sampling weights, strata, and primary sampling units (PSUs) must be accounted for 
        to produce unbiased and efficient estimates."),
                   
                   p("Let \\( y_i \\) denote the binary outcome variable, where \\( y_i = 1 \\) if the \\( i \\)-th individual is classified as overweight 
        or obese, and \\( y_i = 0 \\) otherwise. The probability of \\( y_i = 1 \\) is modeled as:"),
                   
                   p("\\[
        P(y_i = 1 \\mid X_i) = \\frac{\\exp(\\beta_0 + \\beta_1 x_{i1} + \\beta_2 x_{i2} + \\dots + \\beta_k x_{ik})}{1 + \\exp(\\beta_0 + \\beta_1 x_{i1} + \\beta_2 x_{i2} + \\dots + \\beta_k x_{ik})},
      \\]"),
                   
                   p("where \\( X_i = (x_{i1}, x_{i2}, \\dots, x_{ik}) \\) represents the vector of predictor variables for individual \\( i \\), 
        and \\( \\beta_0, \\beta_1, \\dots, \\beta_k \\) are the regression coefficients to be estimated."),
                   
                   p("To account for the complex survey design, the weighted likelihood function is maximized:"),
                   
                   p("\\[
        L(\\beta) = \\prod_{i=1}^n \\left[ P(y_i = 1 \\mid X_i)^{y_i} \\cdot \\left(1 - P(y_i = 1 \\mid X_i)\\right)^{1-y_i} \\right]^{w_i},
      \\]"),
                   
                   p("where \\( w_i \\) denotes the survey sampling weight for individual \\( i \\). Variance estimation incorporates the design's 
        stratification and clustering by using a Taylor-series linearization approach or replicate weights, as implemented 
        in survey analysis software (Lumley, 2010)."),
                   
                   p("This methodology allows for valid statistical inferences that respect the structure of 
        the complex survey data and the population it represents.")
                 ),
                 h3("Reference"),
                 p("Lumley, T. (2011). Complex surveys: a guide to analysis using R. John Wiley & Sons.")
        ),
        tabPanel("PCA Analysis", 
                 h3("PCA in Discrimination-Related Variables"),
                 p("Principal Component Analysis (PCA) is applied to summarize variables related to perceived discrimination, such as experiences based on gender, age, and disability. By reducing data complexity, PCA condenses these variables into composite scores that capture key patterns of discrimination."),
                 
                 h4("Variables Related to Discrimination"),
                 DTOutput("var_table"),
                 
                 h4("PCA for Discrimination Data"),
                 p("PCA reduces the dimensionality of discrimination-related variables, identifying underlying patterns while retaining most information. The first principal component often represents the strongest overall discrimination trend."),
                 p("This app calculates PCA components, using the first few to create a composite score for further analysis."),
                 
                 h4("Cumulative Percentage of Variance"),
                 DTOutput("cum_var"),
                 
                 h4("Discrimination Composite Score"),
                 p("The composite score combines multiple discrimination variables into a single measure, derived from the first 9 principal components (70% variance). Each component is weighted by the proportion of variance it explains, and the score is normalized to a scale of 0–1 or 0–100 for easy interpretation."),
                 
                 h4("Formula for Composite Score"),
                 withMathJax(
                   p("The composite score \\( S \\) is computed as:"),
                   helpText("$$ S = w_1 \\cdot PC_1 + w_2 \\cdot PC_2 + w_3 \\cdot PC_3 + w_4 \\cdot PC_4 + ... + w_9 \\cdot PC_9 $$"),
                   p("Where:"),
                   p("\\( w_i \\): Weight for the \\( i^{th} \\) component, based on the proportion of variance explained."),
                   p("\\( PC_i \\): Score for the \\( i^{th} \\) principal component.")
                 )
        ),
        tabPanel("R Model Summary", 
                 h3("R Model Summary"),
                 verbatimTextOutput("model_summary")),
        tabPanel("Maps", 
                 h3("Geographical variations in the probability of overweight/obesity in Honduras"),
                 leafletOutput("map", height = "500px")),
        tabPanel("Conclusions",
                 h3("Logistic Regression Model"),
                 p("Below are the key findings using the logistic regression model that examines factors associated with being overweight/obese using ENDESA(DHS) data:"),
                 h4("Age Groups"),
                 p("As age increases, the likelihood of being overweight also increases. This is evident from the positive estimates for age categories 20–30, 30–40, and 40–50, with the highest estimate in the 40–50 age group."),
                 h4("Education Level"),
                 p("Higher education levels are associated with a lower likelihood of being overweight. This is indicated by the negative estimates for 'Secondary/Highschool' and 'Higher Education' compared to the reference category."),
                 h4("Discrimination Score"),
                 p("The discrimination score is positively associated with the likelihood of being overweight, suggesting that perceived discrimination may be a contributing factor."),
                 h4("Wealth Index"),
                 p("Higher wealth is associated with an increased likelihood of being overweight. This trend is observed across all wealth categories, with the richest group showing a consistently high estimate."),
                 h4("Significance"),
                 p("Most variables are statistically significant (p < 0.001), indicating strong evidence for their associations with being overweight."),
                 p("Overall, this model suggests that age, wealth, and discrimination are positively associated with overweight status, while higher education levels are protective. The insights from this analysis can guide targeted interventions addressing these factors.")
        )
      )
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  ### This is a test
  output$test <- renderText({
    explain_variable(input$Vars)
  })
  ###
  output$Vartext <- renderText({
    paste(input$Vars,": ",explain_variable(input$Vars))
  })
  
  level_choices <- reactive({
    if(!!sym(input$Vars) == "REGION"){
      return(c("All"))
    }else{
      LHS000301 %>% filter(DOMAIN==1) %>% pull(input$Vars) %>% unique()  
    }
  })
  
  # Dynamically create the Levels selectInput
  output$LevelsUI <- renderUI({
    selectInput("Levels", "Select Levels (Map):", choices = level_choices())
  })
  
  ### Probability table
  output$prev_table <- renderDT({
    mod_var_red <- svyglm(formula = as.formula(paste("OVERWEIGHT ~ -1 + ", input$Vars)),
                          design = hond_design_sub, 
                          family = quasibinomial(link="logit"))
    mod_var <-  svyglm(formula = as.formula(paste("OVERWEIGHT ~ -1 + ", input$Vars,input$adj_age,input$adj_educ,input$adj_disc,input$adj_wealth)),
                       design = hond_design_sub, 
                       family = quasibinomial(link="logit"))
    table.db <- data.frame(`Variable`= paste("", input$Vars), `Level`=gsub(x = names(coefficients(mod_var)),
                                                                           pattern = input$Vars,
                                                                           replacement = "") ,
                           `Probability`=round(1/(1 + exp(-1*coefficients(mod_var))),2))  %>% 
      filter(Level %in% ( gsub(x = names(coefficients(mod_var_red)),
                               pattern = input$Vars,
                               replacement = "") ))
    
    datatable(table.db, rownames = FALSE)
  })
  output$model_summary <- renderPrint({
    mod_var <-  svyglm(formula = as.formula(paste("OVERWEIGHT ~ -1 + ", input$Vars,input$adj_age,input$adj_educ,input$adj_disc,input$adj_wealth)), design = hond_design_sub, 
                       family = quasibinomial(link="logit"))
    summary(mod_var)
  })
  
  output$cum_var <- renderDT({
    pca.res = FactoMineR::PCA(X_pca)
    tabl = pca.res$eig %>%  as_tibble() %>% head(10) %>% select(-eigenvalue) 
    tabl$Component = 1:10
    tabl %>%  
      mutate(`percentage of variance` = round(`percentage of variance`,3),
             `cumulative percentage of variance` = round(`cumulative percentage of variance`,3),
             ) %>% 
      select(Component,`percentage of variance`,`cumulative percentage of variance`)
    
  })
  
  ### Creates the table for
  variables <- data.frame(
    Variable = c("VT22A","VT22B", "VT22C", "VT22D", "VT22E", "VT22F","VT22X"),
    Definition = c(
      "Discrimination by Ethnicity or Immigration Status",
      "Discrimination by Gender",
      "Discrimination by Sexual Orientation",
      "Discrimination by Age",
      "Discrimination by Religion or Beliefs",
      "Discrimination by Disability",
      "Discrimination by Any other reason"
    ),
    Options = rep(c("1 = Yes; 2 = No; 8 = Do not know; 9 = Missing"),7)
    )
  
  # Render variable table
  output$var_table <- DT::renderDataTable({
    DT::datatable(variables, options = list(pageLength = 5), rownames = FALSE)
  })
  
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
  
  #### Creating the maps
  ## Loading the shapefile
  shp_mg = sf::read_sf(paste0("~/LHS0003","/data/shps/Shp_mgd.shp")) %>% 
    mutate(DHSREGEN = replace_tildes(DHSREGEN), DHSREGSP = replace_tildes(DHSREGSP) ) %>% 
    filter(CNTRYNAMEE == "Honduras")
  shp_mg$DHSREGEN = toupper(shp_mg$DHSREGEN)
  shp_mg = shp_mg %>% mutate(DHSREGEN = ifelse(DHSREGEN == "RESTO FRANCISCO MORAZAN","FRANCISCO MORAZAN",DHSREGEN))
  shp_mg = shp_mg %>% mutate(DHSREGEN = ifelse(DHSREGEN == "RESTO CORTES","CORTES",DHSREGEN)) 
  
  output$map <- renderLeaflet({
    ## Fit the model for creating the app
    mod_maps <- svyglm(formula = as.formula(paste("OVERWEIGHT ~ -1 + REGION + ",input$Vars)), design = hond_design_sub, 
                       family = quasibinomial(link="logit"))
    
    ### Creating the dataset with predicted values
    db_pred = LHS000301 %>% filter(DOMAIN==1) 
    db_pred$prob_overweight =  predict(mod_maps, type="response")
    
    if(!!sym(input$Vars) == "REGION"){
      db_pred = db_pred %>%  select(REGION,input$Vars,prob_overweight) %>% 
        mutate(prob_overweight= as.numeric(prob_overweight)) %>% distinct()
    }else{
      db_pred = db_pred %>%  select(REGION,input$Vars,prob_overweight) %>% 
        mutate(prob_overweight= as.numeric(prob_overweight)) %>% distinct() %>% 
        filter(!!sym(input$Vars) == input$Levels)
    }

    ### Full join with DHS data
    shp_st_mgd = shp_mg %>% full_join(db_pred %>% 
                                        rename(DHSREGEN = REGION), by = "DHSREGEN") 
  
    
    ## Generate Leaflet map
    leaflet(shp_st_mgd) %>%
      addTiles() %>%  # Add default base map
      setView(lng = -86, lat = 14.5, zoom = 7) %>%  
      addProviderTiles(providers$CartoDB.Positron) %>% 
      addPolygons(
        fillColor = ~colorNumeric(
          #palette = c("yellow", "#FFDBBB", "red"),
          palette = c("#636b2f","yellow", "red"),
          domain = c(0.1,0.92),
          #domain = shp_st_mgd$prob_overweight
        )(prob_overweight),
        weight = 1,
        color = "black",
        fillOpacity = 0.8,
        popup = ~paste0(
          "<strong>Region: </strong>", DHSREGEN, "<br>",
          "<strong>Probability of overweight/obesity: </strong>", round(prob_overweight, 3)
        )
      ) %>%
      addLegend(
        pal = colorNumeric(#palette = c("yellow", "#FFDBBB", "red"),
                           #domain = shp_st_mgd$prob_overweight),
                           palette = c("#636b2f","yellow", "red"),
                           domain = c(0.1,0.92)),
        values = shp_st_mgd$prob_overweight,
        title = "Probability of /n overweight/obesity",
        position = "bottomright"
      )
    
  })
  
}

# Run the application 
shinyApp(ui = ui, server = server)
