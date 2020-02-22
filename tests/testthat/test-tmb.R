test_that("TMB objective function returns results", {

  data <- list(basepop = as.numeric(burkina.faso.females$baseline.pop.counts),
               sx = burkina.faso.females$survival.proportions,
               fx = burkina.faso.females$fertility.rates[4:10, ],
               srb = rep(1.05, ncol(burkina.faso.females$survival.proportions)),
               age_span = 5,
               fx_idx = 4L)
  par <- list(theta = 0)
  
  obj <- TMB::MakeADFun(data = c(model = "ccmpp_tmb", data), parameters = par,
                        DLL = "leapfrog_TMBExports", silent = TRUE)
  
  expect_equal(obj$fn(), 0)
  expect_equal(obj$report()$projpop,
               ccmppR(data$basepop,
                      data$sx,
                      data$fx,
                      data$srb,
                      data$age_span,
                      data$fx_idx))
})
