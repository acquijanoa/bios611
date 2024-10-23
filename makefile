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

report: report.Rmd
	Rscript -e "rmarkdown::render('report.Rmd',output_format='pdf_document',output_file='output/report.pdf')"

derive: data/wm.sav code/LHS000301.R
	Rscript code/LHS000301.R

report_missing: data/wm.sav code/LHS000302.R
	Rscript code/LHS000302.R

prevalence: derived_data/LHS000301.Rdata code/LHS000302.R
	Rscript code/LHS000302.R

current_dir := $(shell pwd)

run_docker:
	@docker run --platform linux/x86_64 -d -p 8787:8787 -e PASSWORD=pass -v "$(current_dir):/home/rstudio/BIOS611_docker" bios611_rstudio

# Target to build the Docker image
build_docker:
	@docker build --platform=linux/x86_64 -t bios611_rstudio .

