# Using RStudio as parent image
FROM rocker/r-ver:4.3.0

RUN /rocker_scripts/install_pandoc.sh
RUN /rocker_scripts/install_quarto.sh

# Install required packages
RUN R -e "install.packages( \
    c('DBI', 'RSQLite', 'xml2', 'rvest', 'lubridate'), \
    dependencies=TRUE, \
    repos='http://cran.rstudio.com/')"

CMD ["/init"]
