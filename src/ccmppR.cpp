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
