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

  obj <- make_tmb_obj(data = tmb_input$data,
                      par = tmb_input$par_init,
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
                         inner_verbose = inner_verbose,
                         calc_outputs = 1L)
  f$mode <- objout$report(f$par.full)
    
  val <- c(f, obj = list(objout))
  class(val) <- "leapfrog_fit"

  val
}

