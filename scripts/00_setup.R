# Define function to install or load packages
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
    "rpart.plot",
    "gridExtra"
    ))

replace_null_with_na <- function(x) {
  if (is.list(x)) { # Checks for whether the item is a sublist 
    lapply(x, replace_null_with_na) # if it is, apply the function for each of the elements within the sublist
  } else { # If it isn't, simply apply the main function
    ifelse(is.null(x) || x == "null", "NA", x) 
  }
}

replace_na_chr <- function(df) { # NOTE function adapted from ChatGPT output
  df <- df %>%
    mutate(across(where(is.character), ~na_if(., "NA")))
 
  return(df)
}

db_table_check <- function(table){
  rows <- dbGetQuery(db, paste0("SELECT COUNT(1) FROM ", table))
  cols <- dbListFields(db, table)
  
  result = list(
    table = table,
    n_rows = rows[[1]],
    col_names = cols)
  return(result)
}

db <- DBI::dbConnect(RSQLite::SQLite(), here("data/parliament_database.sqlite"))
print(paste0("LOG | ", Sys.time(), " | Setup done."))
