test_that("TMB objective function returns results", {

  data(burkina_faso_females, package = "popReconstruct")
  
  data <- list(basepop = as.numeric(burkina.faso.females$baseline.pop.counts),
               sx = burkina.faso.females$survival.proportions,
               fx = burkina.faso.females$fertility.rates[4:10, ],
               srb = rep(1.05, ncol(burkina.faso.females$survival.proportions)),
               age_span = 5,
               fx_idx = 4L,
               census_log_pop = log(burkina.faso.females$census.pop.counts),
               census_year_idx = c(3L, 5L, 7L, 9L))
  par <- list(log_sigma_logpop = 0)
  
  obj <- TMB::MakeADFun(data = c(model = "ccmpp_tmb", data), parameters = par,
                        DLL = "leapfrog_TMBExports", silent = TRUE)
  
  expect_true(is.finite(obj$fn()))
  expect_equal(obj$report()$projpop,
               ccmppR(data$basepop,
                      data$sx,
                      data$fx,
                      data$srb,
                      data$age_span,
                      data$fx_idx))

})
