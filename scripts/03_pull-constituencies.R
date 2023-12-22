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
    lapply(x, replace_null_with_na) # if true, apply fun to each elements in sublist
  } else { # If it isn't, simply apply the main function
    ifelse(is.null(x) || x == "null", "NA", x) 
  }
}

db <- DBI::dbConnect(RSQLite::SQLite(), here("data/parliament_database.sqlite"))


MPs <- dbGetQuery(db,
  "
  SELECT * 
  FROM members 
  ")

constituencies <- MPs$member_latest_constituency %>% 
  unique()

constituencies <- 
  data.frame(
    constituency_id = constituencies
  ) %>%
  mutate(

    cons_name = NA, 
    cons_start_date = NA, 
    cons_end_date = NA,

    last_election_1_electorate = NA,
    last_election_1_turnout = NA,
    last_election_1_majority = NA, 
    last_election_1_result = NA, 
    last_election_1_winning_party = NA,
    last_election_1_election_ID = NA,
    last_election_1_electionDate = NA,
    last_election_1_isGeneralElection = NA,

    last_election_2_electorate = NA,
    last_election_2_turnout = NA,
    last_election_2_majority = NA, 
    last_election_2_result = NA, 
    last_election_2_winning_party = NA,
    last_election_2_election_ID = NA,
    last_election_2_electionDate = NA,
    last_election_2_isGeneralElection = NA,

    last_election_3_electorate = NA,
    last_election_3_turnout = NA,
    last_election_3_majority = NA, 
    last_election_3_result = NA, 
    last_election_3_winning_party = NA,
    last_election_3_election_ID = NA,
    last_election_3_electionDate = NA,
    last_election_3_isGeneralElection = NA,

    last_election_4_electorate = NA,
    last_election_4_turnout = NA,
    last_election_4_majority = NA, 
    last_election_4_result = NA, 
    last_election_4_winning_party = NA,
    last_election_4_election_ID = NA,
    last_election_4_electionDate = NA,
    last_election_4_isGeneralElection = NA,

    shapefile = NA
    )


### Basic details 

pull_const_info <- function(cons_id) {
  url <- paste0(
    "https://members-api.parliament.uk/api/Location/Constituency/",
    cons_id)

    basic_info <- httr::GET(url) |>
    httr::content("parsed")

    return(basic_info)
}

pb <- txtProgressBar(min = 0, max = length(constituencies$constituency_id), style = 3)


print(paste0(Sys.time(), " | BASIC INFO ..."))
cat("\n")

for(i in seq_along(constituencies$constituency_id)) {
  response <- pull_const_info(constituencies$constituency_id[i])
  response <- response[[1]]

  constituencies$cons_name[i] <- response$name
  constituencies$cons_start_date[i] <- response$startDate
  constituencies$cons_end_date[i] <- ifelse(is.null(response$endDate), NA, response$endDate)

  Sys.sleep(0.5)
  setTxtProgressBar(pb, i)
}


saveRDS(constituencies, "data/constituencies_raw_basic.Rds")

print(paste0(Sys.time(), " | BASIC INFO done."))
cat("\n")

### Shape file

# Define function

get_cons_shapefile <- function(cons_id) {
  url <- paste0(
    "https://members-api.parliament.uk/api/Location/Constituency/",
    cons_id,
    "/Geometry")

  shapefile <- httr::GET(url) |>
    httr::content("parsed")

  return(shapefile)
}

# Execute function
pb <- txtProgressBar(min = 0, max = length(constituencies$constituency_id), style = 3)


print(paste0(Sys.time(), " | SHAPE FILES ..."))
cat("\n")

for(i in seq_along(constituencies$constituency_id)) {
  response <- get_cons_shapefile(constituencies$constituency_id[i])
  response <- response[[1]]

  constituencies$shapefile[i] <- response

  Sys.sleep(0.5)
  setTxtProgressBar(pb, i)
}

saveRDS(constituencies, "data/constituencies_raw_shapefiles.Rds")

print(paste0(Sys.time(), " | SHAPE FILES done."))
cat("\n")

### Election results


get_cons_election_results <- function(cons_id) {
  url <- paste0(
    "https://members-api.parliament.uk/api/Location/Constituency/",
    cons_id,
    "/ElectionResults")

  results <- httr::GET(url) |>
    httr::content("parsed")

  return(results)
}

pb <- txtProgressBar(min = 0, max = length(constituencies$constituency_id), style = 3)


print(paste0(Sys.time(), " | ELECTIONS ..."))
cat("\n")

for (i in seq_along(constituencies$constituency_id)) {
  response <- get_cons_election_results(constituencies$constituency_id[i])
  response <- response[[1]]

  constituencies$last_election_1_electorate[i] <- response[[1]]$electorate
  constituencies$last_election_1_turnout[i] <- response[[1]]$turnout  
  constituencies$last_election_1_majority[i] <- response[[1]]$majority
  constituencies$last_election_1_result[i] <- response[[1]]$result
  constituencies$last_election_1_winning_party[i] <- response[[1]]$winningParty$id
  constituencies$last_election_1_election_ID[i] = response[[1]]$electionId
  constituencies$last_election_1_electionDate[i] = response[[1]]$electionDate
  constituencies$last_election_1_isGeneralElection[i] = response[[1]]$isGeneralElection

  constituencies$last_election_2_electorate[i] <- response[[2]]$electorate
  constituencies$last_election_2_turnout[i] <- response[[2]]$turnout 
  constituencies$last_election_2_majority[i] <- response[[2]]$majority
  constituencies$last_election_2_result[i] <- response[[2]]$result
  constituencies$last_election_2_winning_party[i] <- response[[2]]$winningParty$id
  constituencies$last_election_2_election_ID[i] = response[[2]]$electionId
  constituencies$last_election_2_electionDate[i] = response[[2]]$electionDate
  constituencies$last_election_2_isGeneralElection[i] = response[[2]]$isGeneralElection

  constituencies$last_election_3_electorate[i] <- response[[3]]$electorate
  constituencies$last_election_3_turnout[i] <- response[[3]]$turnout  
  constituencies$last_election_3_majority[i] <- response[[3]]$majority
  constituencies$last_election_3_result[i] <- response[[3]]$result
  constituencies$last_election_3_winning_party[i] <- response[[3]]$winningParty$id
  constituencies$last_election_3_election_ID[i] = response[[3]]$electionId
  constituencies$last_election_3_electionDate[i] = response[[3]]$electionDate
  constituencies$last_election_3_isGeneralElection[i] = response[[3]]$isGeneralElection

  constituencies$last_election_4_electorate[i] <- response[[4]]$electorate
  constituencies$last_election_4_turnout[i] <- response[[4]]$turnout   
  constituencies$last_election_4_majority[i] <- response[[4]]$majority
  constituencies$last_election_4_result[i] <- response[[4]]$result
  constituencies$last_election_4_winning_party[i] <- response[[4]]$winningParty$id
  constituencies$last_election_4_election_ID[i] = response[[4]]$electionId
  constituencies$last_election_4_electionDate[i] = response[[4]]$electionDate
  constituencies$last_election_4_isGeneralElection[i] = response[[4]]$isGeneralElection

  Sys.sleep(0.5)
  setTxtProgressBar(pb, i)
}


print(paste0(Sys.time(), " | ELECTIONS done."))
cat("\n")

saveRDS(constituencies, "data/constituencies_raw.Rds")


print(paste0(Sys.time(), " | All done! :)"))
cat("\n")

#### UK HoC library constituency dashboard