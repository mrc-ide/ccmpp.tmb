test_that("TMB objective function returns results", {

  obj <- make_tmb_obj(bff_data, bff_par)

  expect_is(obj, "tmb_obj")
  
  expect_equal(unname(obj$env$last.par),
               unname(unlist(bff_par)))
  
  expect_true(is.finite(obj$fn())) 
  expect_equal(matrix(obj$report(unlist(bff_par))$population, nrow = length(bff_basepop)),
               ccmppR(bff_basepop, bff_sx, bff_fx, bff_gx,
                      bff_data$srb, bff_data$age_span, bff_data$fx_idx)$population)
  
})

test_that("make_tmb_obj() returns error for invalid model", {

  expect_error(make_tmb_obj(bff_data, bff_par, "jibberish_model"),
               "Unknown model\\.")
})

test_that("make_tmb_obj(..., inner_verbose = FALSE) option", {

  obj <- make_tmb_obj(bff_data, bff_par)
  obj_verbose <- make_tmb_obj(bff_data, bff_par, inner_verbose = TRUE)

  expect_silent(obj$fn())
  expect_output(obj_verbose$fn(), "iter.*mgc:.*")
})

test_that("fit_tmb() options control message and warnings", {

  input <- list(data = bff_data, par_init = bff_par)

  expect_message(fit <- fit_tmb(input),
                 "converged: relative convergence \\(4\\)")
  expect_equal(fit$convergence, 0)
  expect_equal(fit$message, "relative convergence (4)")
  
  expect_silent(fit_tmb(input, outer_verbose = FALSE))
  expect_output(
    suppressWarnings(
      suppressMessages(
        fit_tmb(input, inner_verbose = TRUE, max_iter = 1)
      )),
    "iter.*mgc:.")

  expect_warning(fit_3iter <- fit_tmb(input, max_iter = 3),
                 "convergence error: iteration limit reached without convergence \\(10\\)")
  expect_equal(fit_3iter$iterations, 3)
})

test_that("sample_tmb() return values, options, and message", {

  input <- list(data = bff_data, par_init = bff_par)
  fit <- fit_tmb(input, outer_verbose = FALSE)

  a_nsample <- 5
  a_seed <- 28
  expect_silent(sample1 <- sample_tmb(fit, nsample = a_nsample, rng_seed = a_seed))
  expect_equal(ncol(sample1$sample$population), a_nsample)

  sample2 <- sample_tmb(fit, nsample = a_nsample, rng_seed = a_seed)
  expect_equal(sample2$sample, sample1$sample)
  
  ## The logic of this test is that if sample_tmb(..., rng_seed = NULL), then
  ## sample_tmb() should not change the instance RNG, so set.seed() before calling
  ## should persist.
  set.seed(a_seed)
  sample3 <- sample_tmb(fit, nsample = a_nsample)
  expect_equal(sample3$sample, sample1$sample)

  sample4 <- sample_tmb(fit, nsample = a_nsample)
  expect_false(sample4$sample$population[1] == sample1$sample$population[1])
  
  expect_message(sample_tmb(fit, nsample = a_nsample, verbose = TRUE),
                 "Simulating outputs")
})
