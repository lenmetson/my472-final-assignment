library(httr)
library(tidyverse)

pull_n_oral <- function(endpoint_url){
    resp <- GET(paste0(endpoint_url, "?parameters.take=1")) |> httr::content("parsed")
    n <- resp$PagingInfo$GlobalTotal
    return(n)
}

pull_n_written <- function(endpoint_url){
    resp <- GET(paste0(endpoint_url, "?parameters.take=1")) |> httr::content("parsed")
    n <- resp$totalResults
    return(n)
}

get_qs <- function(endpoint_url, n_skip = 0){
    url <- paste0(endpoint_url, "?parameters.skip=", n_skip, "&parameters.take=100")

    response <- 
        httr::GET(url) |>
        httr::content("parsed")

    return(response)
}


# Define functions to pull all 
pull_all_oral_qs <- function(endpoint_url){
    
    # Calculate how many questions are in the end point
    n <- pull_n_oral(endpoint_url)


    # Questions can be pulled in batches of 100, calculate how many time we will have to pull
    n_loops <- ceiling(n/100)

    for(i in 1:n_loops){ 

        n_skip <- (i-1)*100 # Skip however many 100s the loop has run

        if(i==1){ # On first iteration, make new list

            response <- get_qs(endpoint_url, n_skip)
            response <- response$Response

        } else { # On all other iterations, append to existing list 
            responseNew <- get_qs(endpoint_url, n_skip)
            responseNew <- responseNew$Response

            response <- c(response, responseNew) # Merge responses 
        }

        Sys.sleep(1) # Sleep to avoid hammering the API
    }

 return(response)

}

pull_all_written_qs <- function(endpoint_url){
    
    # Calculate how many questions are in the end point
    n <- pull_n_written(endpoint_url)
    # Questions can be pulled in batches of 100, calculate how many time we will have to pull
    n_loops <- ceiling(n/100)

    for(i in 1:n_loops){ 

        n_skip <- (i-1)*100 # Skip however many 100s the loop has run

        if(i==1){ # On first iteration, make new list

            response <- get_qs(endpoint_url, n_skip)
            response <- response$results

        } else { # On all other iterations, append to existing list 
            responseNew <- get_qs(endpoint_url, n_skip)
            responseNew <- responseNew$results

            response <- c(response, responseNew) # Merge responses 
        }

        Sys.sleep(1) # Sleep to avoid hammering the API
    }

 return(response)

}

print(paste0("Oral Qs started at ", Sys.time()))
oral_questions <- pull_all_oral_qs("https://oralquestionsandmotions-api.parliament.uk/oralquestions/list")
saveRDS(written_questions, "data/oral_questions.RDS")
print(paste0("Oral Qs done at ", Sys.time()))


print(paste0("Written Qs started at ", Sys.time()))
written_questions <- pull_all_written_qs("https://questions-statements-api.parliament.uk/api/writtenquestions/questions")
saveRDS(written_questions, "data/written_questions.RDS")
print(paste0("Written Qs done at ", Sys.time()))
