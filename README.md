# MY472 Final Assignment Repository 

The final report can be found here [as an html file](report.html) or [as the raw Rmd file](report.Rmd). 

## Running the code

Some code chunks take a long time to run because they query. The `scripts/` folder contains separate R scripts for any code which takes more than a few minutes to run. These scripts can be run using the bash package `screen` in the background of your own device or any remote device you might use. These scripts also contain additional progress messages compared to the code contained in the [markdown file](report.Rmd). At the start of each chunk where there is a separated R script, there will be a comment identifying which script to run.

This being said, all code is included in the [markdown document](report.Rmd). It can be run end-to-end by changing `eval = FALSE` to `eval = TRUE` and knitting the whole document. 

```{r}
knitr::opts_chunk$set(
    echo = FALSE, 
    eval = FALSE, # Change to eval = TRUE
    message = FALSE, 
    warning = FALSE)

```

Or the code can be run by running each code chunk in order within the [markdown file](report.Rmd). 

## Untracked files

The folder `data/` contains untracked data files. 

The data file is populated as the code runs. You do not need to download any files manually.  After running all code, the data file should include the following files: 

```
|-- data 
    |-- lexicoder_dictionaries
        |-- _MACOSX
        |-- LTDjun2013
            |-- policy_agendas_english.lcd
        |-- policy_topics.zip
    |-- shpfiles
    |-- whole_UK_shapefile
        |-- Data
            |-- GB 
                |-- westminster_const_region.dbf
                |-- westminster_const_region.prj
                |-- westminster_const_region.shp
                |-- westminster_const_region.shx
        |-- OS_zip.zip
    |-- parliament_database.sqlite 
    |-- constituencies_api_raw.Rds
    |-- hoc_library_scrape_raw.Rds
    |-- members_raw.Rds
    |-- oral_questions_2023.RDS
    |-- written_questions_2023.RDS
    |-- placeholder.md

```
