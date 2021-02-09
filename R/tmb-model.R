#' Make TMB objective function object
#'
#' @param data List of TMB data inputs.
#' @param par List of initial parameters for TMB model.
#' @param model Name of TMB model to be used.
#' @param inner_verbose Logical flag whether to print TMB inner optimization
#'   tracing information.
#' @param calc_outputs Logical flag to be passed to model object whether to
#'   calculate outputs not required for objective function.
#'
#' @return TMB objective function object with class `tmb_obj`.
#'
#' @seealso This returns the object created by [TMB::MakeADFun].
#'
#' @export
make_tmb_obj <- function(data,
                         par,
                         model = "ccmpp_tmb",
                         inner_verbose = FALSE,
                         calc_outputs = TRUE) {

  data$model <- model
  data$calc_outputs <- as.integer(calc_outputs)
                                 
  obj <- TMB::MakeADFun(data = data,
                        parameters = par,
                        DLL = "leapfrog_TMBExports",
                        silent = !inner_verbose,
                        random = c("log_basepop", "logit_sx", "log_fx", "gx"))
  class(obj) <- "tmb_obj"
  
  obj
}
  

#' Fit TMB model
#'
#' @param tmb_input A list containing `data` and `par_init`.
#' @param outer_verbose If `TRUE` print function and parameters every iteration.
#' @param inner_verbose If `TRUE` print TMB inner optimization tracing information.
#' @param max_iter Maximum number of iterations.
#'
#' @return Fit model object.
#' 
#' @export
fit_tmb <- function(tmb_input,
                    outer_verbose = TRUE,
                    inner_verbose = FALSE,
                    max_iter = 250
                    ) {

  ## stopifnot(inherits(tmb_input, "tmb_input"))

  if(is.null(tmb_input$model))
    tmb_input$model <- "ccmpp_tmb"

  obj <- make_tmb_obj(data = tmb_input$data,
                      par = tmb_input$par_init,
                      model = tmb_input$model,
                      inner_verbose = inner_verbose,
                      calc_outputs = 0L)

  trace <- if(outer_verbose) 1 else 0
  f <- withCallingHandlers(
    stats::nlminb(obj$par, obj$fn, obj$gr,
                  control = list(trace = trace,
                                 iter.max = max_iter)),
    warning = function(w) {
      if(grepl("NA/NaN function evaluation", w$message))
        invokeRestart("muffleWarning")
    }
  )
  
  if(f$convergence != 0)
    warning(paste("convergence error:", f$message))

  if(outer_verbose)
    message(paste("converged:", f$message))
  
  f$par.fixed <- f$par
  f$par.full <- obj$env$last.par

  objout <- make_tmb_obj(tmb_input$data,
                         tmb_input$par_init,
                         model = tmb_input$model,
                         inner_verbose = inner_verbose,
                         calc_outputs = 1L)
  f$mode <- objout$report(f$par.full)
    
  val <- c(f, obj = list(objout))
  class(val) <- "leapfrog_fit"

  val
}

## #' Calculate Posterior Mean and Uncertainty Via TMB `sdreport()`
## #'
## #' @param naomi_fit Fitted TMB model.
## #'
## #' @export
## report_tmb <- function(naomi_fit) {

##   stopifnot(methods::is(fit, "naomi_fit"))
##   naomi_fit$sdreport <- TMB::sdreport(naomi_fit$obj, naomi_fit$par,
##                                       getReportCovariance = FALSE,
##                                       bias.correct = TRUE)
##   naomi_fit
## }



#' Sample TMB fit
#'
#' @param fit The TMB fit from [fit_tmb()].
#' @param nsample Number of samples to draw.
#' @param rng_seed Seed passed to [set.seed()].
#' @param random_only Logigcal whether to sample only random effects conditional
#'                    on optimized fixed effect values.
#' @param verbose If TRUE prints additional information.
#'
#' @return Fit object with additional list element `sample`.
#' 
#' @export
sample_tmb <- function(fit, nsample = 1000, rng_seed = NULL,
                       random_only = TRUE, verbose = FALSE) {

  if (!is.null(rng_seed)) {
    set.seed(rng_seed)
  }
  
  stopifnot(methods::is(fit, "leapfrog_fit"))
  stopifnot(nsample > 1)

  if (!random_only) {

    if (verbose) message("Calculating joint precision")
    hess <- sdreport_joint_precision(fit$obj, fit$par.fixed)

    if (verbose) message("Inverting precision for joint covariance")
    cov <- solve(hess)

    if (verbose) message("Drawing sample")
    smp <- rmvnorm_sparseprec(nsample, fit$par.full, cov)

  } else {

    r <- fit$obj$env$random
    par_f <- fit$par.full[-r]

    par_r <- fit$par.full[r]
    hess_r <- fit$obj$env$spHess(fit$par.full, random = TRUE)
    smp_r <- rmvnorm_sparseprec(nsample, par_r, hess_r)

    smp <- matrix(0, nsample, length(fit$par.full))
    smp[ , r] <- smp_r
    smp[ ,-r] <- matrix(par_f, nsample, length(par_f), byrow = TRUE)
    colnames(smp)[r] <- colnames(smp_r)
    colnames(smp)[-r] <- names(par_f)
  }

  if (verbose) message("Simulating outputs")
  sim <- apply(smp, 1, fit$obj$report)

  r <- fit$obj$report()

  if (verbose) message("Returning sample")
  fit$sample <- Map(vapply, list(sim), "[[", lapply(lengths(r), numeric), names(r))
  is_vector <- vapply(fit$sample, class, character(1)) == "numeric"
  fit$sample[is_vector] <- lapply(fit$sample[is_vector], as.matrix, nrow = 1)
  names(fit$sample) <- names(r)

  fit
}

#' Random sample from multivariate normal distribution with sparse precision matrix
#'
#' This function is similar to [mvtnorm::rmvnorm()] except that instead of
#' argument covariance matrix `sigma`, it takes a precision matrix `prec`
#' inheriting a symmetric sparse matrix class from the Matrix package.
#' 
#' @noRd
rmvnorm_sparseprec <- function(n, mean = rep(0, nrow(prec)), prec = diag(length(mean))) {

  z = matrix(stats::rnorm(n * length(mean)), ncol = n)
  L_inv = Matrix::Cholesky(prec)
  v <- mean + Matrix::solve(methods::as(L_inv, "pMatrix"), Matrix::solve(Matrix::t(methods::as(L_inv, "Matrix")), z))
  as.matrix(Matrix::t(v))
}
