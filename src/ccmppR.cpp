#include <Rcpp.h>
#include <RcppEigen.h>
#include "ccmpp.h"

template <class Type>
Eigen::SparseMatrix<Type>
make_leslie_matrix(const Eigen::Array<Type, Eigen::Dynamic, 1>& sx,
                   const Eigen::Array<Type, Eigen::Dynamic, 1>& fx,
                   const Type srb,
                   const Type age_span,
                   const int fx_idx) {
  
  Type fert_k = sx[0] * 0.5 * age_span / (1.0 + srb);

  int fxd = fx.rows();
  Eigen::Array<Type, Eigen::Dynamic, 1> fert_leslie(fxd + 1);
  fert_leslie.setZero();
  fert_leslie.block(0, 0, fxd, 1) += fx * sx.block(fx_idx, 0, fxd, 1);
  fert_leslie.block(1, 0, fxd, 1) += fx;
  fert_leslie *= fert_k;

  int dim = sx.rows() - 1;
  Eigen::SparseMatrix<Type> leslie(dim, dim);
  leslie.reserve(Eigen::VectorXi::Constant(dim, 2));  // 2 non-zero entries per column

  for (int i = 0; i < fxd+1; i++) {
    leslie.insert(0, fx_idx + i - 1) = fert_leslie[i];
  }

  for (int i = 1; i < dim; i++) {
    leslie.insert(i, i-1) = sx[i];
  }
  leslie.insert(dim-1, dim-1) = sx[dim];
  leslie.makeCompressed();

  return leslie;
}

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
