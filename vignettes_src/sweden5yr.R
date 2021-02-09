#' ---
#' title: "Population in Sweden"
#' output: rmarkdown::html_vignette
#' vignette: >
#'   %\VignetteIndexEntry{Population in Sweden}
#'   %\VignetteEngine{knitr::rmarkdown}
#'   %\VignetteEncoding{UTF-8}
#' ---

##+ include = FALSE
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

##+ setup
devtools::load_all()

## library(leapfrog)
library(dplyr)
library(tidyr)
library(forcats)
library(ggplot2)
library(tmbstan)

##+ datasets
data(swe_lt)
data(swe_fert)

#' # _A header_

#' ## Baseline 5x5 popualtion projection
#'
#' Construct a population projection from 1900 to 2010 for age 0 to 90+ by
#' 5 year age group with no migration.
#'
#' The first step is to calculate life table sx values. Since
#' $s_x = _nL_x / _nL_{x-n}$ and for the open age group is approximated as
#' $s_x = T_x / T_{x-n}$, truncate the life table to one age older (age 95)
#' than the oldest age in the population projection (90+).
#'
#' There is a bit of imprecision here by using `exposure` as population size
#' instead of getting the start of year population data.

##+ swe_lt_sx
swe_lt5 <- swe_lt %>%
  arrange(iso3, sex, year, age) %>%
  mutate(population = exposure * as.integer(year %% 5 == 0),
         year = 5 * floor(year / 5),
         age = pmin(5 * floor(age / 5), 95)) %>%
  group_by(iso3, sex, year, age) %>%
  summarise_at(vars(population, exposure, deaths, Lx), sum) %>%
  group_by(iso3, sex, year) %>%
  mutate(Tx = rev(cumsum(rev(Lx))),
         sx = if_else(age < max(age),
                      Lx / lag(Lx, default = 25 * 1e5),
                      Tx / lag(Tx))) %>%  
  ungroup()

#' For inputs, use the life table 'exposure' for 1900 as the base population.
#' Assume that fertility occurs for women age 15 to 49, and the sex ratio at
#' birth is 1.05

##+ ccmpp_inputs

idx5 <- projection_indices(period_start = 1900,
                           interval = 5,
                           n_periods = 22,
                           n_ages = 19,
                           fx_idx = 4L,
                           n_fx = 7,
                           n_sexes = 1)

mf5 <- projection_model_frames(idx5)


swe_lt5_sx <- swe_lt5 %>%
  filter(sex == "female",
         year %in% idx5$periods) %>%
  arrange(iso3, sex, year, age)

swe_lt5_pop <- swe_lt5 %>%
  filter(sex %in% idx5$sexes,
         year %in% idx5$periods_out) %>%
  mutate(age = pmin(age, max(idx5$ages))) %>%
  group_by(iso3, sex, year, age) %>%
  summarise_at(vars(population, exposure, deaths), sum) %>%
  ungroup()

swe_fert5 <- swe_fert %>%
  mutate(year = 5 * floor(year / 5),
         age = 5 * floor(age / 5)) %>%
  group_by(iso3, year, age) %>%
  summarise_at(vars(births, exposure), sum) %>%
  mutate(asfr = births / exposure) %>%
  filter(year %in% idx5$periods,
         age %in% idx5$fertility_ages) %>%
  arrange(iso3, year, age)


basepop <- filter(swe_lt5_pop, year == min(idx5$periods))$population
sx <- matrix(swe_lt5_sx$sx, length(idx5$ages)+1)
fx <- matrix(swe_fert5$asfr, length(idx5$fertility_ages))
gx <- matrix(0, length(idx5$ages), length(idx5$periods))
srb <- rep(1.05, idx5$n_periods)


##+ simulate_ccmpp

proj <- ccmppR(basepop, sx, fx, gx, srb, idx5$interval, idx5$fx_idx)

mf5$mf_population %>%
  mutate(population = as.vector(proj$population),
         source = "projection (no migration)") %>%
  bind_rows(
    swe_lt5_pop %>%
    select(age, period = year, population) %>%
    mutate(source = "HMD exposure denominator")
  ) %>%
  mutate(source = fct_inorder(source)) %>%
  count(period, source, wt = population) %>%
  ggplot(aes(period, n, linetype = source)) +
  geom_line() +
  scale_y_continuous("Population (millions)",
                      labels = scales::label_number(scale = 1e-6)) +
  expand_limits(y = 0) +
  ggtitle("Sweden population 1900-2010")



#' # PopReconstruct
#'

basepop_init <- basepop
sx_init <- sx
fx_init <- pmax(fx, min(fx[fx > 0]))
gx_init <- gx

log_basepop_mean <- as.vector(log(basepop_init))
logit_sx_mean <- as.vector(qlogis(sx_init))
log_fx_mean <- as.vector(log(fx_init))
gx_mean <- as.vector(gx_init)

census_log_pop <- matrix(log(swe_lt5_pop$population),
                         nrow = length(idx5$ages))
census_year_idx <- seq.int(1, idx5$n_periods + 1, by = 5 / idx5$interval)



deaths_obs <- swe_lt5_pop %>%
  filter(year != max(year)) %>%
  .$deaths %>%
  matrix(nrow = idx5$n_ages)

births_obs <- matrix(swe_fert5$births, nrow = idx5$n_fx)
  
data <- list(log_basepop_mean = log_basepop_mean,
             logit_sx_mean = logit_sx_mean,
             log_fx_mean = log_fx_mean,
             gx_mean = gx_mean,
             srb = srb,
             interval = idx5$interval,
             n_periods = idx5$n_periods,
             fx_idx = idx5$fx_idx,
             n_fx = idx5$n_fx,
             census_log_pop = census_log_pop[ , census_year_idx, drop = FALSE],
             census_year_idx = census_year_idx)

par <- list(log_tau2_logpop = 0,
            log_tau2_sx = 0,
            log_tau2_fx = 0,
            log_tau2_gx = 0,
            log_basepop = log_basepop_mean,
            logit_sx = logit_sx_mean,
            log_fx = log_fx_mean,
            gx = gx_mean)

input <- list(data = data, par_init = par, model = "ccmpp_tmb")

obj <- make_tmb_obj(data, par, inner_verbose = TRUE)
init_sim <- obj$report()

obj$fn()
obj$gr()

fit <- fit_tmb(input)
fit[1:6]

fit <- sample_tmb(fit)

if( !file.exists("swe5yr_fitstan.rds") ) {
  fitstan <- fit_tmbstan(input, chains = 4, iter = 2000,
                         use_inits = TRUE, refresh = 100)
  saveRDS(fitstan, "swe5yr_fitstan.rds")
} else {
  fitstan <- readRDS("swe5yr_fitstan.rds")
}

fitstan <- sample_tmbstan(fitstan, TRUE)


n_samples <- ncol(fit$sample$population)

colnames(fit$sample$population) <- seq_len(n_samples)
colnames(fit$sample$migrations) <- seq_len(n_samples)
colnames(fit$sample$fx) <- seq_len(n_samples)

init_pop <- ccmppR(basepop_init, sx_init, fx_init, gx_init,
                   srb = srb, interval = 5, fx_idx = 4)

df <- crossing(year = c(years, max(years)+1),
               sex = "female",
               age = ages) %>%
  mutate(init_pop = as.vector(init_pop_mat))

census_pop <- crossing(sex = "female",
                       age_group = c(sprintf("%02d-%02d", 0:15*5, 0:15*5+4), "80+")) %>%
  bind_cols(as_tibble(burkina.faso.females$census.pop.counts)) %>%
  gather(year, census_pop, `1975`:`2005`) %>%
  type_convert(cols(year = col_double()))

df <- df %>%
  left_join(census_pop) %>%
  bind_cols(as_tibble(fit$sample$population)) %>%
  gather(sample, value, `1`:last_col())

agepop <- df %>%
  group_by(year, sex, age_group) %>%
  summarise(init_pop = mean(init_pop),
            census_pop = mean(census_pop),
            mean = mean(value),
            lower = quantile(value, 0.025),
            upper = quantile(value, 0.975))

totalpop <- df %>%
  group_by(year, sample) %>%
  summarise(init_pop = sum(init_pop),
            census_pop = sum(census_pop),
            value = sum(value)) %>%
  group_by(year) %>%
  summarise(init_pop = mean(init_pop),
            census_pop = mean(census_pop),
            mean = mean(value),
            lower = quantile(value, 0.025),
            upper = quantile(value, 0.975))


##+ Migrations

migrations <- crossing(year = c(years, years),
                       age_lower = ages) %>%
  mutate(init_migrations = init_sim$migrations) %>%
  bind_cols(as_tibble(fit$sample$migrations)) %>%
  gather(sample, value, `1`:last_col()) 

total_migrations <- migrations %>%
  group_by(year, sample) %>%
  summarise(init_migrations = sum(init_migrations),
            value = sum(value)) %>%
  group_by(year) %>%
  summarise(init_migrations = mean(init_migrations),
         mean = mean(value),
         lower = quantile(value, 0.025),
         upper = quantile(value, 0.975))

total_migrations <- migrations %>%
  group_by(year, sample) %>%
  summarise(init_migrations = sum(init_migrations),
            value = sum(value)) %>%
  group_by(year) %>%
  summarise(init_migrations = mean(init_migrations),
         mean = mean(value),
         lower = quantile(value, 0.025),
         upper = quantile(value, 0.975))


ggplot(total_migrations, aes(year, mean, ymin = lower, ymax = upper)) +
  geom_ribbon(alpha = 0.2) +
  geom_line() +
  geom_line(aes(y = init_migrations), linetype = "dashed") +
  scale_y_continuous("Net migration (000s)",
                     labels = scales::number_format(scale=1e-3)) +
  labs(x = NULL) +
  theme_light() +
  theme(panel.grid = element_blank()) +
  ggtitle("SWE: total net migrations (thousands)")


migrations %>%
  mutate(age_group = cut(age_lower, c(0, 15, 50, Inf),
                         c("0-14", "15-49", "50+"), right = FALSE)) %>%
  group_by(year, age_group, sample) %>%
  summarise(init_migrations = sum(init_migrations),
            value = sum(value)) %>%
  summarise(init_migrations = mean(init_migrations),
            mean = mean(value),
            lower = quantile(value, 0.025),
            upper = quantile(value, 0.975)) %>%
  ggplot(aes(year, mean, ymin = lower, ymax = upper,
             color = age_group, fill = age_group)) +
  geom_ribbon(alpha = 0.2, color = NA) +
  geom_line() +
  geom_line(aes(y = init_migrations), linetype = "dashed") +
  scale_y_continuous("Net migration (000s)",
                     labels = scales::number_format(scale=1e-3)) +
  labs(x = NULL) +
  theme_light() +
  theme(panel.grid = element_blank()) +
  ggtitle("SWE: net migrations by age (thousands)")



#' # PopReconstruct VR
#'


deaths_obs <- swe_lt5_pop %>%
  filter(year != max(year)) %>%
  .$deaths %>%
  matrix(nrow = idx5$n_ages)

births_obs <- matrix(swe_fert5$births, nrow = idx5$n_fx)
  

data_vr <- list(log_basepop_mean = log_basepop_mean,
             logit_sx_mean = logit_sx_mean,
             log_fx_mean = log_fx_mean,
             gx_mean = gx_mean,
             srb = srb,
             interval = idx5$interval,
             n_periods = idx5$n_periods,
             fx_idx = idx5$fx_idx,
             n_fx = idx5$n_fx,
             census_log_pop = census_log_pop[ , census_year_idx, drop = FALSE],
             census_year_idx = census_year_idx,
             deaths_obs = deaths_obs,
             births_obs = births_obs)

par <- list(log_tau2_logpop = 0,
            log_tau2_sx = 0,
            log_tau2_fx = 0,
            log_tau2_gx = 0,
            log_basepop = log_basepop_mean,
            logit_sx = logit_sx_mean,
            log_fx = log_fx_mean,
            gx = gx_mean)

obj_vr <- make_tmb_obj(data_vr,
                    par,
                    model = "ccmpp_vr_tmb",
                    inner_verbose = TRUE)
init_sim <- obj_vr$report()

obj_vr$fn()
obj_vr$gr()

input_vr <- list(data = data_vr, par_init = par, model = "ccmpp_vr_tmb")

fit_vr <- fit_tmb(input_vr, inner_verbose = TRUE)
fit_vr[1:6]

fit_vr <- sample_tmb(fit_vr)


if(!file.exists("swe5yr_fitstan_vr.rds")) {
  fitstan_vr <- fit_tmbstan(input_vr, chains = 4, iter = 1000,
                            use_inits = TRUE, refresh = 100)
  saveRDS(fitstan_vr, "swe5yr_fitstan_vr.rds")
} else {
  fitstan_vr <- readRDS("swe5yr_fitstan_vr.rds")
}


fitstan_vr <- sample_tmbstan(fitstan_vr, TRUE)

fitstan_vr$sample$migrations %>%
  `colnames<-`(seq_len(ncol(.))) %>%
  as_tibble() %>%
  bind_cols(mf5$mf_migrations, .) %>%
  gather(sample, value, `1`:last_col()) %>%
  group_by(period, sample) %>%
  summarise(value = sum(value)) %>%
  summarise(mean = mean(value),
            sd = sd(value),
            lower = quantile(value, 0.025),
            upper = quantile(value, 0.975)) %>%
  print(n = Inf)

fitstan$sample$migrations %>%
  `colnames<-`(seq_len(ncol(.))) %>%
  as_tibble() %>%
  bind_cols(mf5$mf_migrations, .) %>%
  gather(sample, value, `1`:last_col()) %>%
  group_by(period, sample) %>%
  summarise(value = sum(value)) %>%
  summarise(mean = mean(value),
            sd = sd(value),
            lower = quantile(value, 0.025),
            upper = quantile(value, 0.975)) %>%
  print(n = Inf)


fitstan_vr$sample$population %>%
  `colnames<-`(seq_len(ncol(.))) %>%
  as_tibble() %>%
  bind_cols(mf5$mf_population, .) %>%
  gather(sample, value, `1`:last_col()) %>%
  group_by(period, sample) %>%
  summarise(value = sum(value)) %>%
  summarise(mean = mean(value),
            sd = sd(value),
            lower = quantile(value, 0.025),
            upper = quantile(value, 0.975))

fitstan$sample$population %>%
  `colnames<-`(seq_len(ncol(.))) %>%
  as_tibble() %>%
  bind_cols(mf5$mf_population, .) %>%
  gather(sample, value, `1`:last_col()) %>%
  group_by(period, sample) %>%
  summarise(value = sum(value)) %>%
  summarise(mean = mean(value),
            sd = sd(value),
            lower = quantile(value, 0.025),
            upper = quantile(value, 0.975))

fitstan_vr$sample$period_deaths %>%
  `colnames<-`(seq_len(ncol(.))) %>%
  as_tibble() %>%
  bind_cols(mf5$mf_deaths, .) %>%
  gather(sample, value, `1`:last_col()) %>%
  group_by(period, sample) %>%
  summarise(value = sum(value)) %>%
  summarise(mean = mean(value),
            sd = sd(value),
            lower = quantile(value, 0.025),
            upper = quantile(value, 0.975))

fitstan$sample$period_deaths %>%
  `colnames<-`(seq_len(ncol(.))) %>%
  as_tibble() %>%
  bind_cols(mf5$mf_deaths, .) %>%
  gather(sample, value, `1`:last_col()) %>%
  group_by(period, sample) %>%
  summarise(value = sum(value)) %>%
  summarise(mean = mean(value),
            sd = sd(value),
            lower = quantile(value, 0.025),
            upper = quantile(value, 0.975))


fitstan_vr$sample$births %>%
  `colnames<-`(seq_len(ncol(.))) %>%
  as_tibble() %>%
  bind_cols(mf5$mf_births, .) %>%
  gather(sample, value, `1`:last_col()) %>%
  group_by(period, sample) %>%
  summarise(value = sum(value)) %>%
  summarise(mean = mean(value),
            sd = sd(value),
            lower = quantile(value, 0.025),
            upper = quantile(value, 0.975))

fitstan$sample$births %>%
  `colnames<-`(seq_len(ncol(.))) %>%
  as_tibble() %>%
  bind_cols(mf5$mf_births, .) %>%
  gather(sample, value, `1`:last_col()) %>%
  group_by(period, sample) %>%
  summarise(value = sum(value)) %>%
  summarise(mean = mean(value),
            sd = sd(value),
            lower = quantile(value, 0.025),
            upper = quantile(value, 0.975))


fitstan$sample$period_deaths %>%
  `colnames<-`(seq_len(ncol(.))) %>%
  as_tibble() %>%
  bind_cols(mf5$mf_period_deaths, .) %>%
  gather(sample, value, `1`:last_col()) %>%
  group_by(period, sample) %>%
  summarise(value = sum(value)) %>%
  summarise(mean = mean(value),
            sd = sd(value),
            lower = quantile(value, 0.025),
            upper = quantile(value, 0.975))

fitstan$sample$period_deaths %>%
  `colnames<-`(seq_len(ncol(.))) %>%
  as_tibble()
