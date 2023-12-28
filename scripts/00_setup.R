load_packages <- function(x) {
  y <- x %in% rownames(installed.packages())
  if(any(!y)) install.packages(x[!y])
  invisible(lapply(x, library, character.only=T))
  rm(x, y)
}

# Load required packagess
load_packages(c(
    "tidyverse",
    "here",
    # Database management
    "DBI",
    "RSQLite",
    # APIs and webscraping
    "httr",
    "RSelenium",
    # Text analysis 
    "tm", 
    # Geospatial plots
    "tmap", 
    "sf", 
    "ggrepel", 
    # Random forests
    "parallel",
    "ranger",
    "tidymodels",
    "vip", 
    "rpart", 
    "rpart.plot"
    ))

db <- DBI::dbConnect(RSQLite::SQLite(), here("data/parliament_database.sqlite"))


print(paste0("LOG | ", Sys.time(), " | Setup done."))
