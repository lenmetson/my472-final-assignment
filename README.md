# MY472 Final Assignment Repository 

The final report can be found here [as an html file](/notebook/report.html) or [as the raw Qmd file](/notebook/report.qmd). 

## Running the code

Some code chunks take a long time to run because they query. The `scripts/` folder contains separate R scripts for any code which takes more than a few minutes to run. These scripts can be run using the bash package `screen` in the background of your own device or any remote device you might use. These scripts also contain additional progress messages compared to the code contained in the [markdown file](/notebook/report.qmd). At the start of each chunk where there is a separated R script, there will be a comment identifying which script to run.

This being said, all code is included in the [markdown document](/notebook/report.qmd). It can be run end-to-end by changing `eval = FALSE` to `eval = TRUE` and knitting the whole document. 

```{r}
knitr::opts_chunk$set(
    echo = FALSE, 
    eval = FALSE, # Change to eval = TRUE
    message = FALSE, 
    warning = FALSE)

```

Or the code can be run by running each code chunk in order within the [markdown file](/notebook/report.qmd). 

## File structure 

The folder `data/` contains untracked data files. It is populated as the code runs. After running all code, it will include the following files: 

```
|- data 
|-- constituencies_api_raw.Rds
|-- hoc_library_scrape_raw.Rds
|-- members_raw.Rds
|-- oral_questions_2023.RDS
|-- parliament_database.sqlite 
|-- placeholder.md
|-- written_questions_2023.RDS
|- random-forest-outputs
|-- X

```
