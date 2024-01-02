source("scripts/00_setup.R")

# Read in data from the constituency endpoint pull
cons <- readRDS("data/constituencies_api_raw.Rds") 

# Make new dataframe
cons <- cons %>%
  select(constituency_id, cons_name) %>%
  unique() %>% # Keep only unqiue constituencies 
  mutate( # Initialise variables
    region_nation_hoclib23 = NA,
    population_hoclib23 = NA,
    area_hoclib23 = NA,
    age_0_29_hoclib23 = NA,
    age_30_64_hoclib23 = NA,
    age_65_plus_hoclib23 = NA, 
    uc_claimants_hoclib23 = NA, 
    median_house_price_hoclib23 = NA
  )

# Set selinium browser
rD <- rsDriver(browser=c("firefox"), verbose = F, port = netstat::free_port(random = TRUE), chromever = NULL) 
driver <- rD$client

# Define a list of css selectors

selector_list <- list()

selector_list$search_dropdown <- "/html/body/div[1]/report-embed/div/div[1]/div/div/div/div/exploration-container/div/div/docking-container/div/div/div/div/exploration-host/div/div/exploration/div/explore-canvas/div/div[2]/div/div[2]/div[2]/visual-container-repeat/visual-container[1]/transform/div/div[3]/div/div/visual-modern/div/div/div[2]/div/i"

selector_list$search_box <- "/html/body/div[7]/div[1]/div/div[1]/input"

selector_list$search_result <- "/html/body/div[7]/div[1]/div/div[2]/div/div[1]/div/div/div[1]/div/span"

selector_list$region_nation <- "/html/body/div[1]/report-embed/div/div[1]/div/div/div/div/exploration-container/div/div/docking-container/div/div/div/div/exploration-host/div/div/exploration/div/explore-canvas/div/div[2]/div/div[2]/div[2]/visual-container-repeat/visual-container[2]/transform/div/div[3]/div/div/visual-modern/div/div/div/div[1]/div/div/div/div/div"

selector_list$population <- "/html/body/div[1]/report-embed/div/div[1]/div/div/div/div/exploration-container/div/div/docking-container/div/div/div/div/exploration-host/div/div/exploration/div/explore-canvas/div/div[2]/div/div[2]/div[2]/visual-container-repeat/visual-container[3]/transform/div/div[3]/div/div/visual-modern/div/div/div/p[2]/span"

selector_list$area <- "/html/body/div[1]/report-embed/div/div[1]/div/div/div/div/exploration-container/div/div/docking-container/div/div/div/div/exploration-host/div/div/exploration/div/explore-canvas/div/div[2]/div/div[2]/div[2]/visual-container-repeat/visual-container[5]/transform/div/div[3]/div/div/visual-modern/div/div/div/p[2]/span"

selector_list$age_0_29 <- "/html/body/div[1]/report-embed/div/div[1]/div/div/div/div/exploration-container/div/div/docking-container/div/div/div/div/exploration-host/div/div/exploration/div/explore-canvas/div/div[2]/div/div[2]/div[2]/visual-container-repeat/visual-container[11]/transform/div/div[3]/div/div/visual-modern/div/div/div/div[1]/div/div/div/div/div/div[1]"

selector_list$age_30_64 <- "/html/body/div[1]/report-embed/div/div[1]/div/div/div/div/exploration-container/div/div/docking-container/div/div/div/div/exploration-host/div/div/exploration/div/explore-canvas/div/div[2]/div/div[2]/div[2]/visual-container-repeat/visual-container[13]/transform/div/div[3]/div/div/visual-modern/div/div/div/div[1]/div/div/div/div/div/div[1]"

selector_list$age_65_plus <- "/html/body/div[1]/report-embed/div/div[1]/div/div/div/div/exploration-container/div/div/docking-container/div/div/div/div/exploration-host/div/div/exploration/div/explore-canvas/div/div[2]/div/div[2]/div[2]/visual-container-repeat/visual-container[15]/transform/div/div[3]/div/div/visual-modern/div/div/div/div[1]/div/div/div/div/div/div[1]"

selector_list$uc_claimants <- "/html/body/div[1]/report-embed/div/div[1]/div/div/div/div/exploration-container/div/div/docking-container/div/div/div/div/exploration-host/div/div/exploration/div/explore-canvas/div/div[2]/div/div[2]/div[2]/visual-container-repeat/visual-container[28]/transform/div/div[3]/div/div/visual-modern/div/div/div/div[1]/div/div/div/div/div[1]/div[1]"

selector_list$house_prices <- "/html/body/div[1]/report-embed/div/div[1]/div/div/div/div/exploration-container/div/div/docking-container/div/div/div/div/exploration-host/div/div/exploration/div/explore-canvas/div/div[2]/div/div[2]/div[2]/visual-container-repeat/visual-container[39]/transform/div/div[3]/div/div/visual-modern/div/div/div/div[1]/div/div/div/div/div[2]/div[1]"

constituency_dash_scraper <- function(
  constituency_name, 
  wait_base = 1 # Allows user to adjust wait lengths (e.g if running on a slow connection)
                # If you get a 'could not find element' error, try adjusting the wait time as the dashboard takes a while to load 
  ){
  # Find dropdown box and click on it 
  search_dropdown <- driver$findElement(using = "xpath", value = selector_list$search_dropdown)
  search_dropdown$clickElement()
  
  # Find search box and type constituency name
  Sys.sleep(wait_base * 2)
  search_box <- driver$findElement(using = "xpath", value = selector_list$search_box)
  #search_box$clickElement() # Do not strictly need this, but if not working try uncommenting
  search_box$clearElement()
  search_box$sendKeysToElement(list(constituency_name))

  Sys.sleep(wait_base * 4) # This requires a long time to load.
  # Click on the first result to load data
  first_result <- driver$findElement(using = "xpath", value = selector_list$search_result)
  first_result$clickElement()
  
  Sys.sleep(wait_base * 4) # Wait for data to load
  
  # EXTRACT TEXT FROM ELEMENTS

  # Set defaults as NA
  region_nation_text <- NA
  population_text <- NA
  area_text <- NA
  age_0_29_text <- NA
  age_30_64_text <- NA
  age_65_plus_text <- NA
  uc_claimants_text <- NA
  house_prices_text <- NA

  # Region or nation
  tryCatch({ # Prevent loop from closing if no data available
  suppressMessages({ 
    region_nation <- driver$findElement(using = "xpath", value = selector_list$region_nation)
    region_nation_text <- region_nation$getElementText()[[1]]
    })
  }, error = function(e) {
    # Print error message, no need to assign NA as we have set NA as default
    print(paste0("Log: NA assigned for REGION/NATION at iteration ", i))
  })

  # Population 
  tryCatch({
  suppressMessages({ 
    population <- driver$findElement(using = "xpath", value = selector_list$population)
    population_text <- population$getElementText()[[1]]
    })
  }, error = function(e) {
    print(paste0("Log: NA assigned for POPULATION at iteration ", i))
  })

  # Area in sq km
  tryCatch({
  suppressMessages({ 
    area <- driver$findElement(using = "xpath", value = selector_list$area)
    area_text <- area$getElementText()[[1]]
    })
  }, error = function(e) {
    print(paste0("Log: NA assigned for AREA at iteration ", i))
  })

  # Age composition 
  tryCatch({
  suppressMessages({
    age_0_29 <- driver$findElement(using = "xpath", value = selector_list$age_0_29)
    age_0_29_text <- age_0_29$getElementText()[[1]]
    })
  }, error = function(e) {
    print(paste0("Log: NA assigned for AGE 0-29 PLUS at iteration ", i))
  })

  tryCatch({
  suppressMessages({
    age_30_64 <- driver$findElement(using = "xpath", value = selector_list$age_30_64)
    age_30_64_text <- age_30_64$getElementText()[[1]]
    })
  }, error = function(e) {
    print(paste0("Log: NA assigned for AGE 30-64 PLUS at iteration ", i))
  })

  tryCatch({
  suppressMessages({
    age_65_plus <- driver$findElement(using = "xpath", value = selector_list$age_65_plus)
    age_65_plus_text <- age_65_plus$getElementText()[[1]]
    })
  }, error = function(e) {
    print(paste0("Log: NA assigned for AGE 64 PLUS at iteration ", i))
  })

  # Universal credit claimants 
  tryCatch({
  suppressMessages({
    uc_claimants <- driver$findElement(using = "xpath", value = selector_list$uc_claimants)
    uc_claimants_text <- uc_claimants$getElementText()[[1]]
    })
  }, error = function(e) {
    print(paste0("Log: NA assigned for UC CLAIMANTS at iteration ", i))
  })

  # House price
  tryCatch({
    suppressMessages({
      house_prices <- driver$findElement(using = "xpath", value = selector_list$house_prices)
      house_prices_text <- house_prices$getElementText()[[1]]
    })
  }, error = function(e) {
    print(paste0("Log: NA assigned for HOUSE PRICE at iteration ", i))
  })

 # Merge results into a list
  results = list(
    region_nation_text, 
    population_text, area_text, 
    age_0_29_text, age_30_64_text, age_65_plus_text,
    uc_claimants_text, house_prices_text)

  return(results)

}

# Run the scraper

# Navigate to home page outside of the loop to avoid reloading each time
driver$navigate("https://commonslibrary.parliament.uk/constituency-dashboard/")

Sys.sleep(1)

# The dashboard exists within a sub-page. Unless we "switch" to this subframe, the css paths will be broken
# Identify and switch to sub-page 
iframe <- driver$findElement(using = "xpath", value = "//iframe[@title='Constituency dashboard']")
driver$switchToFrame(iframe)
Sys.sleep(4)

# Set the number to start from in case loop is interuppted but we have cached results
start_from = 1 

for (i in start_from:length(cons$constituency_id)) {

  results <- constituency_dash_scraper(cons$cons_name[i], wait_base = 1)

    cons$region_nation_hoclib23[i] <- results[[1]]

    cons$population_hoclib23[i] <- results[[2]]

    cons$area_hoclib23[i] <- results[[3]]

    cons$age_0_29_hoclib23[i] <- results[[4]]
    cons$age_30_64_hoclib23[i] <- results[[5]]
    cons$age_65_plus_hoclib23[i] <- results[[6]]

    cons$uc_claimants_hoclib23[i] <- results[[7]]
    cons$median_house_price_hoclib23[i] <- results[[8]]

 # Cache results collected so far
  if(i == start_from){
    saveRDS(cons, paste0("data/cache_cons_at", i, ".Rds"))
  } else {
     saveRDS(cons, paste0("data/cache_cons_at", i, ".Rds"))
     file.remove(paste0("data/cache_cons_at", i-1, ".Rds")) # delete last cached object
  }
  
  Sys.sleep(1)

  print(paste0(i, " of ", nrow(cons), " done."))

}

# Kill driver and java processes
driver$close()
rD$server$stop()
system("taskkill /im java.exe /f", intern=FALSE, ignore.stdout=FALSE)

# Save output
saveRDS(cons, "data/hoc_library_scrape_raw.Rds")