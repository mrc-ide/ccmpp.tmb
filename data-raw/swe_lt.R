library(readr)
library(dplyr)
library(ggplot2)

#' ## Human mortality database
#' * Downloaded from mortality.org using orderly task:
#'   https://github.com/mrc-ide/hmd-orderly

swe_lt <- read_csv("~/Data/hmd/archive/lifetables/20200304-080809-2fb76c88/ltper/swe_ltper_1x1.csv.gz")

usethis::use_data(swe_lt)


swe_lt %>%
  filter(age == 0, sex != "both") %>%
  ggplot(aes(year, ex, color = sex)) +
  geom_line() +
  scale_color_brewer(palette = "Set1") +
  expand_limits(y = 0) +
  labs(title = "Sweden (SWE) life expectancy at birth", y = "e0") +
  theme_minimal()

swe_lt %>%
  filter(year %% 50 == 0,
         sex == "both") %>%
  mutate(year = factor(year)) %>%
  ggplot(aes(age, Mx, color = year)) +
  geom_line() +
  scale_y_log10("Deaths per 1000", labels = scales::number_format(scale = 1e3, accuracy = 0.1)) +
  labs(title = "Sweden (SWE) age-specific mortality") +
  theme_minimal()
