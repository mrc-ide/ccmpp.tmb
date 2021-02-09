#' Construct indices for population projection
#'
#' @param period_start start of first projection period.
#' @param interval projection interval (e.g. 1 year or 5 year).
#' @param n_periods number of projection periods.
#' @param n_ages number of age groups.
#' @param fx_idx first age index exposed to fertility.
#' @param n_fx number of age groups exposed to fertility.
#' @param sexes sexes included in population projection.
#'
#' @examples
#'
#' indices5 <- projection_indices(period_start = 1950,
#'                               interval = 5,
#'                               n_periods = 12,
#'                               n_ages = 19,
#'                               fx_idx = 4,
#'                               n_fx = 7,
#'                               n_sexes = 1)
#' 
#' @export
projection_indices <- function(period_start, interval, n_periods, n_ages,
                               fx_idx, n_fx, n_sexes = 1) {

  stopifnot(n_sexes %in% 1:2)

  periods_out <- period_start + 0:n_periods * interval
  periods <- periods_out[-length(periods_out)]
  ages <- 0:(n_ages - 1) * interval
  fertility_ages <- ages[fx_idx + 0:(n_fx - 1L)]
  sexes <- if(n_sexes == 1) "female" else c("female", "male")
  
  list(periods = periods,
       periods_out = periods_out,
       ages = ages,
       fertility_ages = fertility_ages,
       sexes = sexes,
       interval = interval,
       n_periods = n_periods,
       n_ages = n_ages,
       fx_idx = fx_idx,
       n_fx = n_fx,
       n_sexes = n_sexes)
}

#' @rdname projection_indices
#' @param indices list of indices, from [projection_indices()].
projection_model_frames <- function(indices) {

  mf_population <- tidyr::crossing(period = indices$periods_out,
                                   sex = indices$sexes,
                                   age = indices$ages)

  mf_deaths <- tidyr::crossing(period = indices$periods,
                               sex = indices$sexes,
                               age = indices$ages)

  cohort_death_ages <- c(indices$ages, max(indices$ages) + indices$interval)
  mf_cohort_deaths <- tidyr::crossing(period = indices$periods,
                                      sex = indices$sexes,
                                      age = cohort_death_ages)

  mf_migrations <- tidyr::crossing(period = indices$periods,
                                   sex = indices$sexes,
                                   age = indices$ages)

  mf_births <- tidyr::crossing(period = indices$periods,
                               age = indices$fertility_ages)

  list(mf_population = mf_population,
       mf_deaths = mf_deaths,
       mf_cohort_deaths = mf_cohort_deaths,
       mf_migrations = mf_migrations,
       mf_births = mf_births)
}


#' Convert projection output to long format
#'
#' @param proj CCMPP projection output from [`ccmppR()`].
#' @param mf model frames list from [`projection_model_frames()`].
#' @param value_col column name for projection output.
#'
proj_to_long <- function(proj, mf, value_col = "value") {

  val <- list()
  val$population <- mf$mf_population
  val$population[[value_col]] <- as.vector(proj$population)

  val$population <- mf$mf_cohort_deaths
  val$population[[value_col]] <- as.vector(proj$cohort_deathsg)
  
}
