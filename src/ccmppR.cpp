#include <Rcpp.h>
#include <RcppEigen.h>
#include "ccmpp.h"

//' Construct a sparse Leslie matrix
//'
//' @param sx a vector of survivorship probabilities.
//' @param fx a vector of fertility rates, only amongst fertile ages.
//' @param srb sex ratio at birth.
//' @param age_span the interval for age and projection time step.
//' @param fx_idx first in
//'
//' @return A sparse matrix representation of a Leslie matrix.
//'
//' @details
//' The first index of fertility `fx_idx` must be greater than 1, that is, it is
//' assumed there is no fertility in the youngest age group. The reason for this
//' restriction is that fertility among the youngest age group would require 
//' calculation of offspring among births during the second half of the
//' projection interval.
//'
//' @examples
//'
//' library(popReconstruct)
//' data(burkina_faso_females)
//' make_leslie_matrixR(sx = burkina.faso.females$survival.proportions[,1],
//'                     fx = burkina.faso.females$fertility.rates[4:10, 1],
//'                     srb = 1.05,
//'                     age_span = 5,
//'                     fx_idx = 4)
//'
//' @importClassesFrom Matrix dgCMatrix
//' @export
// [[Rcpp::export]]
Eigen::SparseMatrix<double>
make_leslie_matrixR(const Eigen::Map<Eigen::ArrayXd> sx,
                    const Eigen::Map<Eigen::ArrayXd> fx,
                    double srb,
                    double age_span,
                    int fx_idx) {
  
  return make_leslie_matrix<double>(sx, fx, srb, age_span, fx_idx - 1);
}


//' Simulate cohort component population projection
//'
//' @param basepop vector of baseline population size.
//' @param sx a matrix of survivorship probabilities.
//' @param fx a matrix of fertility rates, only amongst fertile ages.
//' @param gx a matrix of proportion of migrants during projection period.
//' @param srb a vector of sex ratio at birth.
//' @param age_span the interval for age and projection time step.
//' @param fx_idx first in
//'
//' @return
//' `ccmppR()` returns a list with matrices for population, (cohort)
//' deaths, births by age, number of infants, and migrations.
//'
//' `ccmpp_leslieR()` simulates the same population projection using a 
//' Leslie matrix formulation and returns a matrix of population. This
//' is exactly equal to `population` returned by `ccmppR()` (see examples).
//'
//' @details
//' Arguments `sx`, `fx`, and `gx` are matrices with one column for each
//' projection period, and `srb` is a vector of length number of projection 
//' periods.
//'
//' The number of age groups in the cohort deaths array are one greater than the 
//' number of age groups because deaths are counted separately for those ageing 
//' into the open ended age group and survivors in the open ended age group.
//'
//' @examples
//'
//' library(popReconstruct)
//' data(burkina_faso_females)
//'
//' bf_basepop <- as.numeric(burkina.faso.females$baseline.pop.counts)
//' bf_sx <- burkina.faso.females$survival.proportions
//' bf_fx <- burkina.faso.females$fertility.rates[4:10, 1]
//' bf_gx <- burkina.faso.females$migration.proportions
//' bf_srb <- rep(1.05, ncol(burkina.faso.females$survival.proportions))
//'
//' pop_leslie <- ccmpp_leslieR(basepop = bf_basepop, sx = bf_sx, fx = bf_fx,
//'                             gx = bf_gx, srb = bf_srb, 
//'                             age_span = 5, fx_idx = 4)
//' pop_proj <- ccmppR(basepop = bf_basepop, sx = bf_sx, fx = bf_fx,
//'                    gx = bf_gx, srb = bf_srb, 
//'                    age_span = 5, fx_idx = 4)
//' 
//' all(pop_leslie == pop_proj$population)
//'
//' @export
// [[Rcpp::export]]
Rcpp::List
ccmppR(const Eigen::Map<Eigen::VectorXd> basepop,
       const Eigen::Map<Eigen::MatrixXd> sx,
       const Eigen::Map<Eigen::MatrixXd> fx,
       const Eigen::Map<Eigen::MatrixXd> gx,
       const Eigen::Map<Eigen::VectorXd> srb,
       double age_span,
       int fx_idx) {

  PopulationProjection<double> proj(ccmpp<double>(basepop, sx, fx, gx, srb, age_span, fx_idx - 1));

  // !! NOTE: is this copying memory?
  return Rcpp::List::create(Rcpp::Named("population") = proj.population,
			    Rcpp::Named("cohort_deaths") = proj.cohort_deaths,
			    Rcpp::Named("period_deaths") = proj.period_deaths(),
			    Rcpp::Named("births") = proj.births,
			    Rcpp::Named("infants") = proj.infants,
			    Rcpp::Named("migrations") = proj.migrations);
}

//' @rdname ccmppR
//' @export
// [[Rcpp::export]]
Eigen::MatrixXd
ccmpp_leslieR(const Eigen::Map<Eigen::VectorXd> basepop,
	      const Eigen::Map<Eigen::MatrixXd> sx,
	      const Eigen::Map<Eigen::MatrixXd> fx,
	      const Eigen::Map<Eigen::MatrixXd> gx,
	      const Eigen::Map<Eigen::VectorXd> srb,
	      double age_span,
	      int fx_idx) {
  
  return ccmpp_leslie<double>(basepop, sx, fx, gx, srb, age_span, fx_idx - 1);
}
