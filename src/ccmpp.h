#ifndef CCMPP_H
#define CCMPP_H

#include <Eigen/Dense>
#include <Eigen/Sparse>

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

#endif
