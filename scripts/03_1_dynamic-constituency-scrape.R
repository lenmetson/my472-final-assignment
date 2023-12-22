library(RSelenium)


cons <- readRDS("data/test_con_df.Rds")

rD <- rsDriver(browser=c("firefox"), verbose = F, port = netstat::free_port(random = TRUE), chromever = NULL) 

driver <- rD$client


driver$close()
rD$server$stop()
system("taskkill /im java.exe /f", intern=FALSE, ignore.stdout=FALSE)
