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

## library(ccmpp.tmb)
library(dplyr)
library(tidyr)
library(forcats)
library(ggplot2)

##+ datasets
data(swe_lt)
data(swe_fert)

#' # _A header_

#' ## Baseline popualtion projection
#'
#' Construct a population projection from 1900 to 2010 for age 0 to 90+ with
#' no migration.
#'
#' The first step is to calculate life table sx values. Since
#' $s_x = _nL_x / _nL_{x-n}$ and for the open age group is approximated as
#' $s_x = T_x / T_{x-n}$, truncate the life table to one age older (age 91)
#' than the oldest age in the population projection (90+).

##+ swe_lt_sx
swe_lt_trunc <- swe_lt %>%
  arrange(iso3, sex, year, age) %>%
  mutate(age = pmin(age, 91)) %>%
  group_by(iso3, sex, year, age) %>%
  summarise_at(vars(exposure, deaths, Lx), sum) %>%
  group_by(iso3, sex, year) %>%
  mutate(Tx = rev(cumsum(rev(Lx))),
         sx = if_else(age < max(age),
                      Lx / lag(Lx, default = 1e5),
                      Tx / lag(Tx))) %>%  
  ungroup()

#' For inputs, use the life table 'exposure' for 1900 as the base population.
#' Assume that fertility occurs for women age 15 to 49, and the sex ratio at
#' birth is 1.05

##+ ccmpp_inputs
ages <- 0:90
fert_ages <- 15:49
years <- 1900:1919

swe_lt_sx <- swe_lt_trunc %>%
  filter(sex == "female",
         year %in% years) %>%
  arrange(iso3, sex, year, age)

swe_lt_pop <- swe_lt_trunc %>%
  filter(sex == "female",
         year %in% c(years, max(years)+1)) %>%
  mutate(age = pmin(age, max(ages))) %>%
  group_by(iso3, sex, year, age) %>%
  summarise_at(vars(exposure, deaths), sum) %>%
  ungroup()

swe_fert <- swe_fert %>%
  filter(year %in% years,
         age %in% fert_ages) %>%
  arrange(iso3, year, age)


basepop <- filter(swe_lt_pop, year == min(years))$exposure
sx <- matrix(swe_lt_sx$sx, length(ages)+1)
fx <- matrix(swe_fert$asfr, length(fert_ages))
gx <- matrix(0, length(ages), length(years))
srb <- rep(1.05, length(years))


##+ simulate_ccmpp

age_span <- 1
fx_idx <- 16L

proj <- ccmppR(basepop, sx, fx, gx, srb, age_span, fx_idx)

proj_population <- proj$population %>%
  `dimnames<-`(list(age = ages, year = c(years, max(years)+1))) %>%
  as.data.frame.table(responseName = "population") %>%
  type.convert() %>%
  as_tibble()

proj_population %>%
  mutate(source = "projection (no migration)") %>%
  bind_rows(
    swe_lt_pop %>%
    select(age, year, population = exposure) %>%
    mutate(source = "HMD exposure denominator")
  ) %>%
  mutate(source = fct_inorder(source)) %>%
  count(year, source, wt = population) %>%
  ggplot(aes(year, n, linetype = source)) +
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

census_log_pop <- matrix(log(swe_lt_pop$exposure), nrow = length(ages))
census_year_idx <- seq(to = length(years), by = 1) + 1
  
data <- list(log_basepop_mean = log_basepop_mean,
             logit_sx_mean = logit_sx_mean,
             log_fx_mean = log_fx_mean,
             gx_mean = gx_mean,
             srb = srb,
             age_span = 1,
             n_steps = ncol(sx_init),
             fx_idx = 16L,
             n_fx = length(fert_ages),
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

obj <- make_tmb_obj(data, par, inner_verbose = TRUE)
init_sim <- obj$report()

data$model <- "ccmpp_tmb"
data$calc_outputs <- 1L
inner_verbose <- TRUE

par_opt <- obj$env$parList()

obj <- TMB::MakeADFun(data = data,
                      parameters = par_opt,
                      DLL = "ccmpp.tmb_TMBExports",
                      silent = !inner_verbose,
                      random = c("log_basepop", "logit_sx", "log_fx", "gx"),
                      calc_outputs = FALSE)

class(obj) <- "tmb_obj"


system.time(obj$fn())
system.time(obj$gr())

input <- list(data = data, par_init = par)
fit <- fit_tmb(input, inner_verbose = TRUE)

fit <- readRDS("fit.rds")
fit[1:6]

fit <- sample_tmb(fit)


n_samples <- ncol(fit$sample$population)

colnames(fit$sample$population) <- seq_len(n_samples)
colnames(fit$sample$migrations) <- seq_len(n_samples)
colnames(fit$sample$fx) <- seq_len(n_samples)

init_pop <- ccmppR(basepop_init, sx_init, fx_init, gx_init,
                   srb = srb, age_span = 5, fx_idx = 4)

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
