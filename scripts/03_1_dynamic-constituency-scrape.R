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


consituency_dash_scraper <- function(constituency_name){

  driver$navigate("https://commonslibrary.parliament.uk/constituency-dashboard/")

  Sys.sleep(5)

  iframe <- driver$findElement(using = "xpath", value = "//iframe[@title='Constituency dashboard']")
  driver$switchToFrame(iframe)

  Sys.sleep(3)
  search_dropdown <- driver$findElement(using = "xpath", value = selector_list$search_dropdown)
  search_dropdown$clickElement()

  Sys.sleep(3)
  search_box <- driver$findElement(using = "xpath", value = selector_list$search_box)
  #search_box$clickElement()
  search_box$clearElement()
  Sys.sleep(1)
  search_box$sendKeysToElement(list(constituency_name))

  Sys.sleep(3)
  first_result <- driver$findElement(using = "xpath", value = selector_list$search_result)
  first_result$clickElement()


  # Extract text 

  Sys.sleep(4)

  region_nation <- driver$findElement(using = "xpath", value = selector_list$region_nation)
  region_nation_text <- region_nation$getElementText()[[1]]

  population <- driver$findElement(using = "xpath", value = selector_list$population)
  population_text <- population$getElementText()[[1]]

  area <- driver$findElement(using = "xpath", value = selector_list$area)
  area_text <- area$getElementText()[[1]]

  age_0_29 <- driver$findElement(using = "xpath", value = selector_list$age_0_29)
  age_0_29_text <- age_0_29$getElementText()[[1]]

  age_30_64 <- driver$findElement(using = "xpath", value = selector_list$age_30_64)
  age_30_64_text <- age_30_64$getElementText()[[1]] 

  age_65_plus <- driver$findElement(using = "xpath", value = selector_list$age_65_plus)
  age_65_plus_text <- age_65_plus$getElementText()[[1]]

  uc_claimants <- driver$findElement(using = "xpath", value = selector_list$uc_claimants)
  uc_claimants_text <- uc_claimants$getElementText()[[1]]

  house_prices <- driver$findElement(using = "xpath", value = selector_list$house_prices)
  house_prices_text <- house_prices$getElementText()[[1]]

  Sys.sleep(1)

  results = list(
    region_nation_text, 
    population_text, area_text, 
    age_0_29_text, age_30_64_text, age_65_plus_text,
    uc_claimants_text, house_prices_text)

  return(results)

}



for (i in 14:16) { #length(cons$constituency_id)

  results <- constituency_dash_scraper(cons$cons_name[i])

    cons$region_nation_hoclib23[i] <- results[[1]]

    cons$population_hoclib23[i] <- results[[2]]

    cons$area_hoclib23[i] <- results[[3]]

    cons$age_0_29_hoclib23[i] <- results[[4]]
    cons$age_30_64_hoclib23[i] <- results[[5]]
    cons$age_65_plus_hoclib23[i] <- results[[6]]

    cons$uc_claimants_hoclib23[i] <- results[[7]]
    cons$median_house_price_hoclib23[i] <- results[[8]]

 # Cache results collected so far
  if(i == 1){
    saveRDS(cons, paste0("data/cache_cons_at", i, ".Rds"))
  } else {
     saveRDS(cons, paste0("data/cache_cons_at", i, ".Rds"))
     file.remove(paste0("data/cache_cons_at", i-1, ".Rds")) # delete last cached object
  }
  

  Sys.sleep(2)

  print(paste0(i, " of ", nrow(cons), " done."))

}

driver$close()
rD$server$stop()
system("taskkill /im java.exe /f", intern=FALSE, ignore.stdout=FALSE)

saveRDS(cons, "data/hoc_library_scrape_raw.Rds")

# # Clean data 

# cons2 <- cons
# cons <- cons2

# # pop numeric 
# cons$population_hoclib23 <- cons$population_hoclib23 %>%
#   str_remove_all(",") %>%
#   as.numeric()

# # area numeric

# cons$area_hoclib23 <- cons$area_hoclib23 %>%
#   str_extract(".*(?=\\s*sq\\.\\s*km)") %>%
#   str_remove_all(",") %>%
#   as.numeric()


# # age perc

# cons$age_0_29_hoclib23 <- cons$age_0_29_hoclib23 %>%
#   str_extract_all("[0-9]") %>%
#   as.numeric()

# cons <- cons %>%
#  mutate(age_0_29_hoclib23 = age_0_29_hoclib23/100)

# # uc numeric
# #house price numeric

# # Write out ot db 