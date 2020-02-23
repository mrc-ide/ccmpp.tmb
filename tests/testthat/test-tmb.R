test_that("TMB objective function returns results", {

  obj <- make_tmb_obj(bff_data, bff_par)

  expect_is(obj, "tmb_obj")
  
  expect_equal(unname(obj$env$last.par),
               unname(unlist(bff_par)))
  
  expect_true(is.finite(obj$fn())) 
  expect_equal(obj$report(unlist(bff_par))$projpop,
               ccmppR(bff_basepop, bff_sx, bff_fx, bff_gx,
                      bff_data$srb, bff_data$age_span, bff_data$fx_idx))
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
