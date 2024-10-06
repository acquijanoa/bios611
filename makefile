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
