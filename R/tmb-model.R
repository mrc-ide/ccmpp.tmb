#' Make TMB objective function object
#'
#' @param data List of TMB data inputs.
#' @param par List of initial parameters for TMB model.
#' @param model Name of TMB model to be used.
#' @param inner_verbose Logical flag whether to print TMB inner optimization
#'   tracing information.
#'
#' @return TMB objective function object with class `tmb_obj`.
#'
#' @seealso This returns the object created by [TMB::MakeADFun].
#'
#' @export
make_tmb_obj <- function(data, par, model = "ccmpp_tmb", inner_verbose = FALSE) {

  data$model <- model
                                 
  obj <- TMB::MakeADFun(data = data,
                        parameters = par,
                        DLL = "leapfrog_TMBExports",
                        silent = !inner_verbose,
                        random = c("log_basepop", "logit_sx", "log_fx", "gx"))
  class(obj) <- "tmb_obj"
  
  obj
}
  
