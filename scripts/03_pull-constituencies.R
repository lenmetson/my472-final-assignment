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
  LIMIT 100
  ")

constituencies <- MPs$member_latest_constituency %>% 
  unique()

constituencies <- 
  data.frame(
    constituency_id = constituencies
  ) %>%
  mutate(

    GE19_electorate = NA,
    GE19_turnout = NA,
    GE19_majority = NA, 
    GE19_result = NA, 
    GE19_winning_party = NA,

    GE17_electorate = NA,
    GE17_turnout = NA,
    GE17_majority = NA, 
    GE17_result = NA, 
    GE17_winning_party = NA,

    GE15_electorate = NA,
    GE15_turnout = NA,
    GE15_majority = NA, 
    GE15_result = NA, 
    GE15_winning_party = NA,

    GE10_electorate = NA,
    GE10_turnout = NA,
    GE10_majority = NA, 
    GE10_result = NA, 
    GE10_winning_party = NA,

    shapefile = NA
    )


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

for(i in seq_along(constituencies$constituency_id)) {
  response <- get_cons_shapefile(constituencies$constituency_id[i])
  response <- response[[1]]

  constituencies$shapefile[i] <- response

  Sys.sleep(0.5)
  setTxtProgressBar(pb, i)
}

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

for (i in seq_along(constituencies$constituency_id)) {
  response <- get_cons_election_results(constituencies$constituency_id[i])
  response <- response[[1]]

  constituencies$GE19_electorate[i] <- response[[1]]$electorate
  constituencies$GE19_turnout[i] <- response[[1]]$turnout  
  constituencies$GE19_majority[i] <- response[[1]]$majority
  constituencies$GE19_result[i] <- response[[1]]$result
  constituencies$GE19_winning_party[i] <- response[[1]]$winningParty$id

  constituencies$GE17_electorate[i] <- response[[2]]$electorate
  constituencies$GE17_turnout[i] <- response[[2]]$turnout 
  constituencies$GE17_majority[i] <- response[[2]]$majority
  constituencies$GE17_result[i] <- response[[2]]$result
  constituencies$GE17_winning_party[i] <- response[[2]]$winningParty$id

  constituencies$GE15_electorate[i] <- response[[3]]$electorate
  constituencies$GE15_turnout[i] <- response[[3]]$turnout  
  constituencies$GE15_majority[i] <- response[[3]]$majority
  constituencies$GE15_result[i] <- response[[3]]$result
  constituencies$GE15_winning_party[i] <- response[[3]]$winningParty$id

  constituencies$GE10_electorate[i] <- response[[4]]$electorate
  constituencies$GE10_turnout[i] <- response[[4]]$turnout   
  constituencies$GE10_majority[i] <- response[[4]]$majority
  constituencies$GE10_result[i] <- response[[4]]$result
  constituencies$GE10_winning_party[i] <- response[[4]]$winningParty$id

  Sys.sleep(0.5)
  setTxtProgressBar(pb, i)
}




GE19_electorate <- response[[1]]$electorate

    GE19_majority = NA, 
    GE19_result = NA, 
    GE19_winning_party = NA,

GE_17 <- response[2]
GE_15 <- response[3]
GE_10 <- response[3]
