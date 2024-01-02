source("scripts/00_setup.R")


GET_qs_written <- function(endpoint_url, n_skip = 0) {
  url <- paste0(
    endpoint_url,
    "?skip=",
    n_skip,
    "&tabledWhenFrom=2023-01-01&tabledWhenTo=2023-12-31", # Limit to 2023
    "&house=Commons", # Limit to HoC # TODO add this to report
    "&take=100")   
  
  response <-
    httr::GET(url) %>%
    httr::content("parsed") # Use :: because tm masks content 

  return(response)
}

pull_all_written_qs <- function(endpoint_url){
  
  n_resp <- httr::GET(
    paste0(
      endpoint_url, 
      "?tabledWhenFrom=2023-01-01&tabledWhenTo=2023-12-31", # Limit to 2023
      "&house=Commons", # Limit to HoC # TODO add this to report
      "&take=1")) %>% 
    httr::content("parsed")

    n <- n_resp$totalResults

    # Questions can be pulled in batches of 100, calculate how many time we will have to pull
    n_loops <- ceiling(n/100)

    for(i in 1:n_loops){

        n_skip <- (i-1)*100 # Skip however many 100s the loop has run

        if(i==1){ # On first iteration, make new list

            response <- GET_qs_written(endpoint_url, n_skip)
            response <- response$results

        } else { # On all other iterations, append to existing list 
            responseNew <- GET_qs_written(endpoint_url, n_skip)
            responseNew <- responseNew$results

            response <- c(response, responseNew) # Merge responses 
        }

    print(paste0("LOG | Written questions | ", Sys.time(), " | ", i, " of ", n_loops, " done.")) # Print progress message

    Sys.sleep(0.5) # Sleep to avoid hammering the API
    }

 print(paste0("LOG | Written questions | ", Sys.time(), " | Written question pull done :)"))
 return(response)

}


written_questions <- pull_all_written_qs("https://questions-statements-api.parliament.uk/api/writtenquestions/questions")


saveRDS(written_questions, "data/written_questions_2023.RDS")