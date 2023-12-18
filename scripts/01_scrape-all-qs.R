library(httr)
library(tidyverse)

print("--------------------------------------------------")
print("--------------------------------------------------")

## DEFINE FUNCTIONS

get_qs <- function(endpoint_url, n_skip = 0) {
  url <- paste0(
    endpoint_url,
    "?parameters.skip=",
    n_skip,
    "&parameters.take=100")

  response <-
    GET(url) |>
    content("parsed")

  return(response)
}

# Define functions to pull all questions

pull_all_oral_qs <- function(endpoint_url){

  # Calculate how many questions are in the end point
  n_resp <- GET(paste0(endpoint_url, "?parameters.take=1")) |>
    content("parsed")
  n <- n_resp$PagingInfo$GlobalTotal

  # Questions can be pulled in batches of 100,
  # calculate how many time we will have to pull
  n_loops <- ceiling(n / 100)

  print(paste0("Oral Qs done at ", Sys.time()))

  for (i in 1:n_loops) {

    n_skip <- (i - 1) * 100 # Skip however many 100s the loop has run

    if (i == 1) { # On first iteration, make new list

      response <- get_qs(endpoint_url, n_skip)
      response <- response$Response

    } else { # On all other iterations, append to existing list

      response_new <- get_qs(endpoint_url, n_skip)
      response_new <- response_new$Response
      response <- c(response, response_new) # Merge responses

    }

    print(paste0(i, " of ", n_loops, " done.")) # Print progress message
    Sys.sleep(1) # Sleep to avoid hammering the API

  }

  print(paste0("Oral Qs done at ", Sys.time()))
  return(response)
}

pull_all_written_qs <- function(endpoint_url){

  # Calculate how many questions are in the end point
  n_resp <- GET(paste0(endpoint_url, "?parameters.take=1")) |>
    content("parsed")
  n <- n_resp$totalResults


  # Questions can be pulled in batches of 100,
  # calculate how many time we will have to pull
  n_loops <- ceiling(n / 100)

  print(paste0("Written Qs started at ", Sys.time()))

  for (i in 1:n_loops) {

    n_skip <- (i - 1) * 100 # Skip however many 100s the loop has run

    if (i == 1) { # On first iteration, make new list

      response <- get_qs(endpoint_url, n_skip)
      response <- response$results

    } else { # On all other iterations, append to existing list

      response_new <- get_qs(endpoint_url, n_skip)
      response_new <- response_new$results
      response <- c(response, response_new) # Merge responses

    }

    print(paste0(i, " of ", n_loops, " done.")) # Print progress message
    Sys.sleep(1) # Sleep to avoid hammering the API 

  }

  print(paste0("Written Qs done at ", Sys.time()))
  return(response)
}

## APPLY FUNCTIONS

# oral_questions <- pull_all_oral_qs(
#   "https://oralquestionsandmotions-api.parliament.uk/oralquestions/list")

# saveRDS(oral_questions, "data/oral_questions.RDS")

written_questions <- pull_all_written_qs(
  "https://questions-statements-api.parliament.uk/api/writtenquestions/questions")

saveRDS(written_questions, "data/written_questions.RDS")



