#include <TMB.hpp>
#include "ccmpp.h"

template<class Type>
Type objective_function<Type>::operator() ()
{

  DATA_VECTOR(basepop);
  DATA_VECTOR(sx);
  DATA_VECTOR(fx);
  DATA_SCALAR(srb);
  DATA_SCALAR(age_span);
  DATA_INTEGER(fx_idx);

  PARAMETER(theta);

  Eigen::SparseMatrix<Type> leslie(make_leslie_matrix<Type>(sx, fx, srb, age_span, fx_idx - 1));

  vector<Type> projpop(leslie * basepop);

  REPORT(projpop);

  return Type(0);
}
