.PHONY: clean init

init:
	mkdir -p derived_data
	mkdir -p figures
	mkdir -p output
clean:
	rm -rf derived_data
	rm -rf figures
	rm -rf output
	rm -f report.pdf
	mkdir -p derived_data
	mkdir -p figures
	mkdir -p output


report: output/prevalence_tables.png output/map_age.png output/map_urban.png output/map_wealth.png output/map_educ.png  code/report.Rmd
	Rscript -e "rmarkdown::render('code/report.Rmd',output_format='pdf_document',output_file='../output/report.pdf')"

derived_data/LHS000301.Rdata: data/wm.sav code/LHS000301.R
	Rscript code/LHS000301.R

output/prevalence_tables.png: derived_data/LHS000301.Rdata code/LHS000303.R
	Rscript code/LHS000303.R

output/map_age.png output/map_educ.png output/map_urban.png output/map_wealth.png: derived_data/LHS000301.Rdata code/LHS000304.R
	Rscript code/LHS000304.R

current_dir := $(shell pwd)


# Target to build the Docker image
build_docker:
	@docker build --platform=linux/x86_64 -t shiny-sf-leaflet .

# Run the shiny container
run_shiny_container: derived_data/LHS000301.Rdata
	@docker run --rm \
	--platform linux/amd64 \
	-p 3838:3838 \
	-v "$(PWD):/home/rstudio/LHS0003" \
	shiny-sf-leaflet \
	Rscript -e "shiny::runApp('/home/rstudio/LHS0003/code/LHS000398/app.R', port = 3838, host = '0.0.0.0')"

