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

# Function defined by ChatGPT and adapted for the specific list structure here
replace_null_with_na <- function(x) {
  if (is.list(x)) { # Checks for whether the item is a sublist 
    lapply(x, replace_null_with_na) # if it is, apply the function for each of the elements within the sublist
  } else { # If it isn't, simply apply the main function
    ifelse(is.null(x) || x == "null", "NA", x) 
  }
}

pull_members <- function(base_url, df) {

  cat("\n")
  print(paste0("Started at ", Sys.time()))
  cat("\n")

  pb <- txtProgressBar(min = 0, max = nrow(df), style = 3)
  
  for (i in seq_along(df$member_asking_Mnis_ID)) {

    url <- paste0(base_url, "/", df$member_asking_Mnis_ID[i], "?detailsForDate=", df$question_tabled_when[i]) 

    if (i == 1) {

      response <- GET(url) %>%
        content("parsed")
      response <- response[1]
      response <- c(date = df$question_tabled_when[i], response[[1]])

      response <- list(response)

    } else {
      response_new <- GET(url) %>% content("parsed")
      response_new <- response_new[1]
      response_new <- c(date = df$question_tabled_when[i], response_new[[1]])

      response_new <- list(response_new)

      response <- c(response, response_new) # Merge responses
    }

    Sys.sleep(0.5)

    setTxtProgressBar(pb, i)


  }

  cat("\n")
  print(paste0("Done at ", Sys.time(), " :))"))
  
  return(response)
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

saveRDS(members, "data/members_raw.Rds")

members <- readRDS("data/members_raw.Rds")

members <-  lapply(members, function(lst) {lapply(lst, replace_null_with_na)})

pb <- txtProgressBar(min = 0, max = length(members), style = 3)

for (i in seq_along(members)) {

  if (i == 1) {

    members_df <- members[i] %>%
      unlist() %>%
      t() %>%
      data.frame()

  } else {
    members_df_new <- members[i] %>%
      unlist() %>%
      t() %>%
      data.frame()

    members_df <- rbind(members_df, members_df_new)
  }
  
  setTxtProgressBar(pb, i)
  
}

members_df <- members_df %>%
  select(
    member_date_valid = date, 
    member_Mnis_ID = id, 
    member_name_display = nameDisplayAs, 
    member_latest_party = latestParty.id,
    member_gender = gender, 
    member_latest_constituency = latestHouseMembership.membershipFromId,
    member_membership_start_date = latestHouseMembership.membershipStartDate, 
    member_membership_end_date = latestHouseMembership.membershipEndDate,
    member_membership_end_reason = latestHouseMembership.membershipEndReason,
    member_name_full = nameFullTitle,
    member_name_list = nameListAs
  )

members_df <- members_df %>%
  group_by( # Group by all variables apart from date
    member_Mnis_ID,
    member_name_display,
    member_latest_party,
    member_gender,
    member_latest_constituency,
    member_membership_start_date,
    member_membership_end_date,
    member_membership_end_reason,
    member_name_full,
    member_name_list
  ) %>%
  summarize( # Summarise earliest date this is valid for and latest. This gives us a range of vlaues where this combination is duplicated 
    member_date_valid_min = min(member_date_valid), 
    member_date_valid_max = max(member_date_valid)
  )

dbWriteTable(db, "members", members_df, overwrite = TRUE)

# Disconnect from local database
DBI::dbDisconnect(db)
