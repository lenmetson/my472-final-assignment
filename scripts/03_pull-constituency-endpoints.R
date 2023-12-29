source("scripts/00_setup.R")

MPs <- dbGetQuery(db,
  "
  SELECT * 
  FROM members 
  ")

constituencies <- MPs$latest_constituency %>% 
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

### Pull basic details 

pull_const_info <- function(cons_id) {
  url <- paste0(
    "https://members-api.parliament.uk/api/Location/Constituency/",
    cons_id)

    basic_info <- httr::GET(url) %>%
    httr::content("parsed")

    return(basic_info)
}

for(i in seq_along(constituencies$constituency_id)) {
  response <- pull_const_info(constituencies$constituency_id[i])
  response <- response[[1]]

  constituencies$cons_name[i] <- response$name
  constituencies$cons_start_date[i] <- response$startDate
  constituencies$cons_end_date[i] <- ifelse(is.null(response$endDate), NA, response$endDate)

  Sys.sleep(0.5)
  print(paste0("LOG | Constituency API call - basic | ", Sys.time(), " | ", i, " of ", length(constituencies$constituency_id), " done"))

}


print(paste0("LOG | Constituency API call - basic | ", Sys.time(), " | DONE "))

### Pull shape file

get_cons_shapefile <- function(cons_id) {
  url <- paste0(
    "https://members-api.parliament.uk/api/Location/Constituency/",
    cons_id,
    "/Geometry")

  shapefile <- httr::GET(url) %>%
    httr::content("parsed")

  return(shapefile)
}

for(i in seq_along(constituencies$constituency_id)) {
  response <- get_cons_shapefile(constituencies$constituency_id[i])
  response <- response[[1]]

  constituencies$shapefile[i] <- response

  Sys.sleep(0.5)
  print(paste0("LOG | Constituency API call - shapefile | ", Sys.time(), " | ", i, " of ", length(constituencies$constituency_id), " done"))
}

print(paste0("LOG | Constituency API call - shapefile | ", Sys.time(), " | DONE "))

### Pull election results

get_cons_election_results <- function(cons_id) {
  url <- paste0(
    "https://members-api.parliament.uk/api/Location/Constituency/",
    cons_id,
    "/ElectionResults")

  results <- httr::GET(url) %>%
    httr::content("parsed")

  return(results)
}

for (i in seq_along(constituencies$constituency_id)) {
  response <- get_cons_election_results(constituencies$constituency_id[i])
  response <- response[[1]]

  response <- lapply(response, function(lst) {lapply(lst, replace_null_with_na)})

  constituencies$last_election_1_electorate[i] <- response[[1]]$electorate
  constituencies$last_election_1_turnout[i] <- response[[1]]$turnout  
  constituencies$last_election_1_majority[i] <- response[[1]]$majority
  constituencies$last_election_1_result[i] <- response[[1]]$result
  # If no winner recorded, skip this and assign NA
  if(length(response[[1]]$winningParty) > 1) { # When there is content in the winning party sublist, the length will be greater than 1
    constituencies$last_election_1_winning_party[i] <- response[[1]]$winningParty$id
  } else {
     constituencies$last_election_1_winning_party[i] <- NA
  }
  constituencies$last_election_1_election_ID[i] = response[[1]]$electionId
  constituencies$last_election_1_electionDate[i] = response[[1]]$electionDate
  constituencies$last_election_1_isGeneralElection[i] = response[[1]]$isGeneralElection

  constituencies$last_election_2_electorate[i] <- response[[2]]$electorate
  constituencies$last_election_2_turnout[i] <- response[[2]]$turnout 
  constituencies$last_election_2_majority[i] <- response[[2]]$majority
  constituencies$last_election_2_result[i] <- response[[2]]$result
  # If no winner recorded, skip this and assign NA
  if(length(response[[2]]$winningParty) > 1) {
    constituencies$last_election_2_winning_party[i] <- response[[2]]$winningParty$id
  } else {
     constituencies$last_election_2_winning_party[i] <- NA
  }
  constituencies$last_election_2_election_ID[i] = response[[2]]$electionId
  constituencies$last_election_2_electionDate[i] = response[[2]]$electionDate
  constituencies$last_election_2_isGeneralElection[i] = response[[2]]$isGeneralElection

  constituencies$last_election_3_electorate[i] <- response[[3]]$electorate
  constituencies$last_election_3_turnout[i] <- response[[3]]$turnout  
  constituencies$last_election_3_majority[i] <- response[[3]]$majority
  constituencies$last_election_3_result[i] <- response[[3]]$result
  # If no winner recorded, skip this and assign NA
  if(length(response[[3]]$winningParty) > 1) {
    constituencies$last_election_3_winning_party[i] <- response[[3]]$winningParty$id
  } else {
     constituencies$last_election_3_winning_party[i] <- NA
  }
  constituencies$last_election_3_election_ID[i] = response[[3]]$electionId
  constituencies$last_election_3_electionDate[i] = response[[3]]$electionDate
  constituencies$last_election_3_isGeneralElection[i] = response[[3]]$isGeneralElection

  constituencies$last_election_4_electorate[i] <- response[[4]]$electorate
  constituencies$last_election_4_turnout[i] <- response[[4]]$turnout   
  constituencies$last_election_4_majority[i] <- response[[4]]$majority
  constituencies$last_election_4_result[i] <- response[[4]]$result
  # If no winner recorded, skip this and assign NA
  if(length(response[[4]]$winningParty) > 1) {
    constituencies$last_election_4_winning_party[i] <- response[[4]]$winningParty$id
  } else {
     constituencies$last_election_4_winning_party[i] <- NA
  }
  constituencies$last_election_4_election_ID[i] = response[[4]]$electionId
  constituencies$last_election_4_electionDate[i] = response[[4]]$electionDate
  constituencies$last_election_4_isGeneralElection[i] = response[[4]]$isGeneralElection

  Sys.sleep(0.5)
  
  print(paste0("LOG | Constituency API call - elections | ", Sys.time(), " | ", i, " of ", length(constituencies$constituency_id), " done"))
}

print(paste0("LOG | Constituency API call - elections | ", Sys.time(), " | DONE "))

saveRDS(constituencies, "data/constituencies_raw.Rds")

print(paste0("LOG | Constituency API call | ", Sys.time(), " | ALL DONE "))