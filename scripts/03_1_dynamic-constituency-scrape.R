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
    "httr",
    "RSelenium"
    ))


cons <- readRDS("data/constituencies_raw_basic.Rds")

cons <- cons %>%
  select(constituency_id, cons_name) %>%
  unique() %>%
  mutate(
    region_nation_hoclib23 = NA,
    population_hoclib23 = NA,
    area_hoclib23 = NA,
    age_0_29_hoclib23 = NA,
    age_30_64_hoclib23 = NA,
    age_65_plus_hoclib23 = NA, 
    uc_claimants_hoclib23 = NA, 
    median_house_price_hoclib23 = NA
  )

rD <- rsDriver(browser=c("firefox"), verbose = F, port = netstat::free_port(random = TRUE), chromever = NULL) 
driver <- rD$client

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


#constituency_name <- cons$cons_name[16]
#wait_base = 1

constituency_dash_scraper <- function(constituency_name, wait_base = 1){
  #Sys.sleep(wait_base * 4)
  search_dropdown <- driver$findElement(using = "xpath", value = selector_list$search_dropdown)
  search_dropdown$clickElement()

  Sys.sleep(wait_base * 2)
  search_box <- driver$findElement(using = "xpath", value = selector_list$search_box)
  #search_box$clickElement()
  search_box$clearElement()
  search_box$sendKeysToElement(list(constituency_name))

  Sys.sleep(wait_base * 4)
  first_result <- driver$findElement(using = "xpath", value = selector_list$search_result)
  first_result$clickElement()

  # Extract text 
  
  # Set defaults as NA

  region_nation_text <- NA
  population_text <- NA
  area_text <- NA
  age_0_29_text <- NA
  age_30_64_text <- NA
  age_65_plus_text <- NA
  uc_claimants_text <- NA
  house_prices_text <- NA

  Sys.sleep(wait_base * 4)

  # Region or nation
  tryCatch({
  suppressMessages({ 
    region_nation <- driver$findElement(using = "xpath", value = selector_list$region_nation)
    region_nation_text <- region_nation$getElementText()[[1]]
    })
  }, error = function(e) {
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


  results = list(
    region_nation_text, 
    population_text, area_text, 
    age_0_29_text, age_30_64_text, age_65_plus_text,
    uc_claimants_text, house_prices_text)

  return(results)

}

# Navigate to home page outside of the loop
driver$deleteAllCookies()
driver$navigate("https://commonslibrary.parliament.uk/constituency-dashboard/")

Sys.sleep(1)

# Identify and switch to sub-page 
iframe <- driver$findElement(using = "xpath", value = "//iframe[@title='Constituency dashboard']")
driver$switchToFrame(iframe)
Sys.sleep(4)

start_from = 1 # Set the number to start from
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

driver$close()
rD$server$stop()
system("taskkill /im java.exe /f", intern=FALSE, ignore.stdout=FALSE)

saveRDS(cons, "data/hoc_library_scrape_raw.Rds")