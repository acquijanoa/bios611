Hi, this is my 611 Data Science Project. 

**Author**: Álvaro Quijano

**Department:** UNC Biostatistics

**In MacOs**,

- Build the docker container as  follows:

		docker build --platform=linux/x86_64 -t bios611_rstudio . 

- Run the docker container as follows: 

		docker run --platform linux/x86_64 -d -p 8787:8787 -e PASSWORD=pass -v "$(pwd)":/home/rstudio/BIOS611_docker bios611_rstudio


**Folder organization: **
├- Dockerfile
├─README.md
├── code
│   └── LHS000301.R
├── data
│   └── wm.sav
├── derived_data
│   └── LHS000301.Rdata
├── figures
├── makefile
├── output
│   └── report.pdf
├--report.Rmd
