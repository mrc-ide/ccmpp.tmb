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

  // census data
  DATA_MATRIX(census_log_pop);
  DATA_IVECTOR(census_year_idx);

  matrix<Type> projpop(ccmpp<Type>(basepop, sx, fx, srb, age_span, fx_idx-1));
    
  Type nll(0.0);
  
  PARAMETER(log_sigma_logpop);
  Type sigma_logpop(exp(log_sigma_logpop));
  nll -= log_sigma_logpop; // change of variable

  for(int i = 0; i < census_year_idx.size(); i++) {
    nll -= dnorm(vector<Type>(census_log_pop.col(i)),
		 log(vector<Type>(projpop.col(census_year_idx[i]))),
		 sigma_logpop, true).sum();
  }

  REPORT(projpop);

  return Type(nll);
}

#undef TMB_OBJECTIVE_PTR
#define TMB_OBJECTIVE_PTR this

#endif
