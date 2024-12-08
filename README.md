BIOS 611 Data Science Project

Author: Álvaro Quijano  
Department: UNC Biostatistics  

This project demonstrates the use of Docker, Shiny apps for data science workflows. Below are instructions for setting up the project environment, building and running Docker containers, and executing key project tasks.

![Example Visualization](data/img1.png)

---

Setting Up the Project

On macOS:

1. Build the Docker container:  
   Use the following command to build the Docker container:
   docker build --platform=linux/x86_64 -t bios611_rstudio .

2. Run the Docker container:  
   Use the command below to start the container:
   docker run --platform linux/x86_64 -d -p 8787:8787 -e PASSWORD=pass -v "$(pwd)":/home/rstudio/BIOS611_docker bios611_rstudio

---

Project Structure

Directories:
- derived_data/ – Contains processed datasets.
- figures/ – Stores generated plots and visualizations.
- output/ – Contains reports and final outputs.

Makefile Tasks:

- Initialize directories:
  make init

- Clean and recreate directories:
  make clean

- Run the Shiny app locally:
  make run_shiny

- Generate the report:
  make report

- Build the Docker image:
  make build_docker

- Run the Shiny app in a Docker container:
  make run_shiny_container

---

Shiny Application Deployment

This project includes a Shiny app implementation that utilizes a custom Docker image called shiny-sf-leaflet. This image is configured to handle spatial data visualization with Shiny, sf, and leaflet.

Run the Shiny app inside a container:
docker run --rm \
  --platform linux/amd64 \
  -p 3838:3838 \
  -v "$(PWD):/home/rstudio/LHS0003" \
  shiny-sf-leaflet \
  Rscript -e "shiny::runApp('/home/rstudio/LHS0003/code/LHS000398/app.R', port = 3838, host = '0.0.0.0')"

Access the Shiny app:
After running the above command, the Shiny app will be accessible at:
http://localhost:3838

---

Report Generation

The report is generated using R Markdown and includes:
- Prevalence tables
- Maps visualizing age, urbanization, wealth, and education data

To generate the report, run:
make report

---

Data Dependencies

- Input file: data/wm.sav  
- Code scripts:
  - code/LHS000301.R: Processes the input data and saves the derived dataset.
  - code/LHS000303.R: Generates prevalence tables.
  - code/LHS000304.R: Creates various map visualizations.

Derived datasets and visualizations are saved in the appropriate directories (derived_data/, output/, figures/).

---

Acknowledgments

This project is part of the BIOS 611 Data Science curriculum at UNC Biostatistics. The work showcases the integration of Docker with R-based workflows, including Shiny applications and spatial data visualization.
