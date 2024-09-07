FROM rocker/rstudio

RUN apt update && \
	 apt install -y man-db manpages && \
	yes | unminimize && \
	rm -rf /var/lib/apt/list/*

RUN apt-get clean && \
	rm -rf /var/lib/apt/lists/*
