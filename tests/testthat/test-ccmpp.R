test_that("sparse leslie matrix returns expected matrix", {

  surv <- c(0.762, 0.878, 0.971, 0.973, 0.958, 0.948, 0.946, 0.939, 0.926, 
            0.905, 0.875, 0.832, 0.774, 0.697, 0.593, 0.455, 0.318, 0.210)
  fert <- c(0.231, 0.365, 0.308, 0.258, 0.178, 0.091, 0.020)
  srb <- 1.05
  interval <- 5
  fx_idx <- 4

  lesM <- Matrix::Matrix(0, nrow = 17, ncol = 17)
  lesM[cbind(2:17, 1:16)] <- surv[2:17]
  lesM[17, 17] <- surv[18]
  
  k <- interval / (1 + srb) * surv[1] * 0.5
  dbl_fert <- c(0, fert) + c(fert, 0) * surv[fx_idx + 0:7]
  lesM[1, fx_idx + -1:6] <- k * dbl_fert
  lesM <- as(lesM, "dgCMatrix")

  expect_equal(make_leslie_matrixR(surv, fert, srb, interval, fx_idx), lesM)
})

test_that("population projection matches popReconstruct implementation", {

  data(burkina_faso_females, package = "popReconstruct")
  bff <- burkina.faso.females

  popproj_check <- popReconstruct::popRecon.ccmp.female(
                                     pop = bff$baseline.pop.counts,
                                     surv = bff$survival.proportions,
                                     fert = bff$fertility.rates,
                                     mig = bff$migration.proportions)
  
  popproj <- ccmppR(basepop = as.numeric(bff$baseline.pop.counts),
                    sx = bff$survival.proportions,
                    fx = bff$fertility.rates[4:10, ],
                    gx = bff$migration.proportions,
                    srb = rep(1.05, ncol(bff$survival.proportions)),
                    interval = 5,
                    fx_idx = 4)

  expect_equal(popproj$population, popproj_check)
  
})

test_that("projection outputs satisfy balancing equation", {

  data(burkina_faso_females, package = "popReconstruct")
  bff <- burkina.faso.females

  bff_srb <- rep(1.05, ncol(bff$survival.proportions))
  
  proj <- ccmppR(basepop = as.numeric(bff$baseline.pop.counts),
                 sx = bff$survival.proportions,
                 fx = bff$fertility.rates[4:10, ],
                 gx = bff$migration.proportions,
                 srb = bff_srb,
                 interval = 5,
                 fx_idx = 4)

  n_periods <- ncol(bff$survival.proportions)

  check_proj <- colSums(proj$population[ , -(n_periods+1)]) +
    colSums(proj$infants) + colSums(proj$migrations) - colSums(proj$cohort_deaths)

  expect_equal(colSums(proj$population[ , -1]), check_proj)
    
  expect_equal(colSums(proj$cohort_deaths),
               colSums(proj$period_deaths))

  expect_equal(colSums(proj$births) / (1 + bff_srb), colSums(proj$infants))
  
})
