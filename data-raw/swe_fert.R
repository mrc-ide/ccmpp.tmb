library(readr)
library(dplyr)


#' ## Sweden births data from Human Fertility Database
#' * Downloaded from https://www.humanfertility.org/
#' * https://www.humanfertility.org/cgi-bin/getfile.plx?f=zip\SWE.zip

tmpd <- tempfile()
unzip("~/Data/human fertility database/SWE/SWE.zip", exdir = tmpd)

births <- read_table(file.path(tmpd, "Files/SWE/20200128/SWEbirthsRR.txt"), skip = 2)
pys <- read_table(file.path(tmpd, "Files/SWE/20200128/SWEexposRR.txt"), skip = 2)

swe_fert <- births %>%
  rename(births = Total) %>%
  mutate(Age = as.integer(gsub("[^0-9]", "", Age))) %>%
  full_join(pys, by = c("Year", "Age")) %>%
  rename_all(tolower) %>%
  mutate(iso3 = "SWE",
         asfr = births / exposure) %>%
  select(iso3, everything())
  
usethis::use_data(swe_fert)
