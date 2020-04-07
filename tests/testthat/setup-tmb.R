data(burkina_faso_females, package = "popReconstruct")

bff_basepop <- as.numeric(burkina.faso.females$baseline.pop.counts)
bff_sx <- burkina.faso.females$survival.proportions
bff_fx <- burkina.faso.females$fertility.rates[4:10, ]
bff_gx <- burkina.faso.females$migration.proportions

bff_data <- list(log_basepop_mean = log(bff_basepop),
                 logit_sx_mean = as.vector(qlogis(bff_sx)),
                 log_fx_mean = as.vector(log(bff_fx)),
                 gx_mean = as.vector(bff_gx),
                 srb = rep(1.05, ncol(burkina.faso.females$survival.proportions)),
                 interval = 5,
                 n_periods = ncol(burkina.faso.females$survival.proportions),
                 fx_idx = 4L,
                 n_fx = 7L,
                 census_log_pop = log(burkina.faso.females$census.pop.counts),
                 census_year_idx = c(4L, 6L, 8L, 10L))

bff_par <- list(log_tau2_logpop = 0,
                log_tau2_sx = 0,
                log_tau2_fx = 0,
                log_tau2_gx = 0,
                log_basepop = bff_data$log_basepop_mean,
                logit_sx = bff_data$logit_sx_mean,
                log_fx = bff_data$log_fx_mean,
                gx = bff_data$gx_mean)
