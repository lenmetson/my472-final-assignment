library(RSelenium)


cons <- readRDS("data/test_con_df.Rds")

# Use ss command instead of netstat to identify a random free port 
free_port <- system("ss -tan | awk '{print $4}' | cut -d':' -f2 | grep -E '^[0-9]+$' | sort -n | awk '{++a[$1]} END {for (i in a) if (a[i]==1) {print i; exit}}'", intern = TRUE)

rD <- 
  rsDriver(
    browser="firefox",
    version = "latest", 
    verbose = F, 
    port = as.integer(free_port[1]), 
    chromever = NULL) 


driver <- rD$client





driver$close()
rD$server$stop()
system("taskkill /im java.exe /f", intern=FALSE, ignore.stdout=FALSE)
