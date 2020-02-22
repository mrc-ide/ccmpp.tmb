#ifndef CCMPP_TMB_HPP
#define CCMPP_TMB_HPP

#undef TMB_OBJECTIVE_PTR
#define TMB_OBJECTIVE_PTR obj

#include "../ccmpp.h"

template<class Type>
Type ccmpp_tmb(objective_function<Type>* obj)
{

  DATA_VECTOR(basepop);
  DATA_MATRIX(sx);
  DATA_MATRIX(fx);
  DATA_VECTOR(srb);
  DATA_SCALAR(age_span);
  DATA_INTEGER(fx_idx);

  PARAMETER(theta);

  matrix<Type> projpop(ccmpp<Type>(basepop, sx, fx, srb, age_span, fx_idx-1));

  REPORT(projpop);

  return Type(0);
}

#undef TMB_OBJECTIVE_PTR
#define TMB_OBJECTIVE_PTR this

#endif
