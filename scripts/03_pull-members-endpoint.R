source("scripts/00_setup.R")

print(paste0("LOG Member Pull | ", Sys.time(), " | Starting"))

pull_members <- function(base_url, df) {

  for (i in seq_along(df$member_id)) {

    url <- paste0( # Build request URL
      base_url, "/",
      df$member_id[i],
      "?detailsForDate=",
      df$question_tabled_when[i])

    if (i == 1) { # If 1st iteration, create response,

      response <- httr::GET(url) %>% httr::content("parsed") # Pull request
      response <- response[1] # Extract list with response
      response <- c(
        date = df$question_tabled_when[i], response[[1]]) # Merge with date
      response <- list(response) # Convert to list

    } else { #  else create response2, then merge
      response_new <- httr::GET(url) %>% httr::content("parsed")
      response_new <- response_new[1]
      response_new <- c(
        date = df$question_tabled_when[i], response_new[[1]])
      response_new <- list(response_new)

      response <- c(response, response_new) # Merge responses
    }

    Sys.sleep(0.5)

    print(paste0("LOG Member Pull | ", Sys.time(), " | ", i, " of ", nrow(df), " done"))
  }
  return(response)
}

# Query question table to get MP-date pairs

members_asking <- dbGetQuery(db,
  "
  SELECT 
    asking_member AS member_id, 
    question_tabled_when
  FROM oral_questions
  ")

ministers_answering <- dbGetQuery(db,
  "
  SELECT 
    answering_member AS member_id,
    question_tabled_when
  FROM oral_questions
  ")

q_parameters <- rbind(members_asking, ministers_answering)

# Only keep unique MP-date pairs to avoid pulling the same information twice
q_parameters <- unique(q_parameters) %>%
  filter(member_id != 0) # Remove 0s because these indicate no minister has answered

# Apply function to pull members 
members <- pull_members(
  "https://members-api.parliament.uk/api/Members",
  q_parameters)

saveRDS(members, "data/members_raw.Rds")

print(paste0("LOG Member Pull | ", Sys.time(), " |  All done, file saved :)"))