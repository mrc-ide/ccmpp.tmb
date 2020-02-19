#ifndef CCMPP_H
#define CCMPP_H

template <class Type>
Eigen::SparseMatrix<Type>
make_leslie_matrix(const Eigen::Array<Type, Eigen::Dynamic, 1>& sx,
                   const Eigen::Array<Type, Eigen::Dynamic, 1>& fx,
                   const Type srb,
                   const Type age_span,
                   const int fx_idx);

#endif
