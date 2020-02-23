test_that("TMB objective function returns results", {

  data(burkina_faso_females, package = "popReconstruct")

  basepop <- as.numeric(burkina.faso.females$baseline.pop.counts)
  sx <- burkina.faso.females$survival.proportions
  fx <- burkina.faso.females$fertility.rates[4:10, ]
  gx <- burkina.faso.females$migration.proportions
  log_basepop_mean <- log(basepop)
  logit_sx_mean <- as.vector(qlogis(sx))
  log_fx_mean <- as.vector(log(fx))
  gx_mean <- as.vector(gx)

  data <- list(log_basepop_mean = log_basepop_mean,
               logit_sx_mean = logit_sx_mean,
               log_fx_mean = log_fx_mean,
               gx_mean = gx_mean,
               srb = rep(1.05, ncol(burkina.faso.females$survival.proportions)),
               age_span = 5,
               n_steps = ncol(burkina.faso.females$survival.proportions),
               fx_idx = 4L,
               fx_span = 7L,
               census_log_pop = log(burkina.faso.females$census.pop.counts),
               census_year_idx = c(4L, 6L, 8L, 10L))
  par <- list(log_tau2_logpop = 0,
              log_tau2_sx = 0,
              log_tau2_fx = 0,
              log_tau2_gx = 0,
              log_basepop = log_basepop_mean,
              logit_sx = logit_sx_mean,
              log_fx = log_fx_mean,
              gx = gx_mean)
  
  obj <- TMB::MakeADFun(data = c(model = "ccmpp_tmb", data), parameters = par,
                        DLL = "leapfrog_TMBExports", silent = TRUE)
  
  expect_true(is.finite(obj$fn()))
  expect_equal(obj$report()$projpop,
               ccmppR(basepop, sx, fx, gx, data$srb, data$age_span, data$fx_idx))

})
