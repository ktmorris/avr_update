## set seed for reproducibility. this is a random 5-digit number: floor(runif(1)*100000)
set.seed(71390)

bad_states <- c("AK", "CT", "CO", "OR", "VT")


tracts_regs <- readRDS("temp/tract_count_regs.rds") %>% 
  filter(!(state %in% bad_states)) %>% 
  mutate(treated = state == "GA")

tracts_regs <- left_join(tracts_regs,
                         group_by(fips_codes, state) %>% 
                           filter(row_number() == 1) %>% 
                           select(state, state_code)) %>% 
  mutate(GEOID = paste0(state_code,
                        str_pad(Voters_FIPS, 3, side = "left", pad = "0"),
                        str_pad(Residence_Addresses_CensusTract, 6, pad = "0", side = "left"))) %>% 
  select(GEOID, week, year, regs = n, treated)

census_14 <- readRDS("../regular_data/census_tracts_14.rds")

tracts_regs <- left_join(tracts_regs, census_14) %>% 
  filter(!is.na(population)) %>% 
  select(GEOID, treated, week, year, regs, population, latino, nh_black, nh_white,
         median_income, some_college, median_age, share_non_citizen,
         share_no_car, pop_dens)

saveRDS(tracts_regs, "temp/tr_census.rds")

onep <- tracts_regs %>% 
  group_by(GEOID) %>% 
  filter(row_number() == 1) %>% 
  select(-regs, -week, -year) %>% 
  ungroup()


onep <- onep[complete.cases(onep), ]

match_data <- onep %>% 
  select(-GEOID, -treated)

genout <- GenMatch(Tr = onep$treated, X = match_data, replace = T,
                   pop.size = 1000)
