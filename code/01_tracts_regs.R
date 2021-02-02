## run on hpc

library(RSQLite)
library(rgdal)
library(data.table)
library(tidyverse)

db_rolls <- dbConnect(SQLite(), "./data/national_file.db")

fips_codes <- fread("./data/fips_codes.csv")

dbListTables(db_rolls)

national_file <- rbindlist(lapply(dbListTables(db_rolls), function(s){
  scode <- substring(s, 1, 2)
  code_good <- str_pad(as.character(unique(filter(fips_codes, state == scode)$state_code)),
                       pad = "0", side = "left", width = 2)
  d <- dbGetQuery(db_rolls, paste0("select Voters_FIPS,
                                           Residence_Addresses_CensusTract,
                                           Voters_CalculatedRegDate,
                                           state from [", s, "]")) %>% 
    mutate(Voters_CalculatedRegDate = as.Date(Voters_CalculatedRegDate, "%m/%d/%Y"),
           week = lubridate::week(Voters_CalculatedRegDate),
           year = lubridate::year(Voters_CalculatedRegDate)) %>%
    filter(year %in% c(2013, 2017),
           week < 30) %>% 
    group_by(week, year, Voters_FIPS, Residence_Addresses_CensusTract, state) %>% 
    tally()
}))

saveRDS(national_file, "temp/tract_count_regs.rds")