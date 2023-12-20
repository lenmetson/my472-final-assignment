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
    "DBI",
    "RSQLite",
    "httr"
    ))


progress_perc <- function(num_done, total, additional_message = ""){
    cat("\r", paste0(additional_message, " ", round(num_done / total * 100, digits = 10), "% "))
}



pull_members <- function(base_url, df) {

  for (i in seq_along(df$member_asking_Mnis_ID)) {

    url <- paste0(base_url, "/", df$member_asking_Mnis_ID[i], "?detailsForDate=", df$question_tabled_when[i]) 

    if (i == 1) {
      response <- GET(url) %>% content("parsed")
      response <- response[[1]]
    } else {
      response_new <- GET(url) %>% content("parsed")
      response_new <- response_new[[1]]
      response <- c(response, response_new) # Merge responses
    }
    Sys.sleep(2)

    progress_perc(i, length(df$member_asking_Mnis_ID), "Querying:")

  }

  print("Done.")

  return(df)
}

# Connect to database

db <- DBI::dbConnect(RSQLite::SQLite(), here("data/parliament_database.sqlite"))

# Query the question database for the date the question was tables and who asked it 
questions <- dbGetQuery(db, 
  "
  SELECT member_asking_Mnis_ID, question_tabled_when
  FROM oral_questions
  "
)

questions <- unique(questions) # Avoid pulling the same queries by considering unique MP-date combinations

questions <- questions %>%
  mutate(question_tabled_when = str_extract(question_tabled_when, ".+?(?=T)"))

members <- pull_members("https://members-api.parliament.uk/api/Members", questions)


saveRDS(members, "data/members.Rds")

# Disconnect from local database
DBI::dbDisconnect(db)