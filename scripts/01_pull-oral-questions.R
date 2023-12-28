source("scripts/00_setup.R")

GET_qs <- function(endpoint_url, n_skip = 0) {
  url <- paste0(
    endpoint_url,
    "?parameters.skip=",
    n_skip,
    "&parameters.answeringDateStart=2023-01-01&parameters.answeringDateEnd=2023-12-31", # Limit to 2023
    "&parameters.take=100")

  response <-
    httr::GET(url) %>%
    httr::content("parsed") # Use :: because tm masks content 

  return(response)
}

# Define functions to pull all questions

pull_all_oral_qs <- function(endpoint_url){

  # Calculate how many questions are in the end point
  n_resp <- httr::GET(paste0(
    endpoint_url,
    "?parameters.answeringDateStart=2023-01-01&parameters.answeringDateEnd=2023-12-31", # Limit to 2023
    "&parameters.take=1")) %>%
    httr::content("parsed")
  n <- n_resp$PagingInfo$GlobalTotal

  # Questions can be pulled in batches of 100,
  # calculate how many time we will have to pull
  n_loops <- ceiling(n / 100)

  print(paste0("LOG | ", Sys.time(), " | Oral question pull starting"))

  for (i in 1:n_loops) {

    n_skip <- (i - 1) * 100 # Skip however many 100s the loop has run

    if (i == 1) { # On first iteration, make new list

      response <- GET_qs(endpoint_url, n_skip)
      response <- response$Response

    } else { # On all other iterations, append to existing list

      response_new <- GET_qs(endpoint_url, n_skip)
      response_new <- response_new$Response
      response <- c(response, response_new) # Merge responses

    }

    print(paste0("LOG | ", Sys.time(), " | ", i, " of ", n_loops, " done.")) # Print progress message
    Sys.sleep(1) # Sleep to avoid hammering the API

  }

  print(paste0("LOG | ", Sys.time(), " | Oral question pull done :)"))
  return(response)
}

## APPLY FUNCTIONS

oral_questions <- pull_all_oral_qs(
  "https://oralquestionsandmotions-api.parliament.uk/oralquestions/list")

saveRDS(oral_questions, "data/oral_questions_2023.RDS")
