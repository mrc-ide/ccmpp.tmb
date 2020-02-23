#ifndef CCMPP_TMB_HPP
#define CCMPP_TMB_HPP

#undef TMB_OBJECTIVE_PTR
#define TMB_OBJECTIVE_PTR obj

#include "../ccmpp.h"

template<class Type>
Type ccmpp_tmb(objective_function<Type>* obj)
{

  using Eigen::Matrix;
  using Eigen::Map;
  using Eigen::Dynamic;
  
  DATA_VECTOR(log_basepop_mean);
  DATA_VECTOR(logit_sx_mean);
  DATA_VECTOR(log_fx_mean);
  DATA_VECTOR(gx_mean);
  DATA_VECTOR(srb);
  DATA_SCALAR(age_span);
  DATA_INTEGER(n_steps);
  DATA_INTEGER(fx_idx);
  DATA_INTEGER(fx_span);

  // census data
  DATA_MATRIX(census_log_pop);
  DATA_IVECTOR(census_year_idx);

    
  Type nll(0.0);

  // Hyper priors
  
  PARAMETER(log_tau2_logpop);
  nll -= dlgamma(log_tau2_logpop, Type(1.0), Type(1.0 / 0.0109), true);
  Type sigma_logpop(exp(-0.5 * log_tau2_logpop));

  PARAMETER(log_tau2_sx);
  nll -= dlgamma(log_tau2_sx, Type(1.0), Type(1.0 / 0.0109), true);
  Type sigma_sx(exp(-0.5 * log_tau2_sx));

  PARAMETER(log_tau2_fx);
  nll -= dlgamma(log_tau2_fx, Type(1.0), Type(1.0 / 0.0109), true);
  Type sigma_fx(exp(-0.5 * log_tau2_fx));

  PARAMETER(log_tau2_gx);
  nll -= dlgamma(log_tau2_gx, Type(1.0), Type(1.0 / 0.0436), true);
  Type sigma_gx(exp(-0.5 * log_tau2_gx));


  // prior for base population
  PARAMETER_VECTOR(log_basepop);
  nll -= dnorm(log_basepop, log_basepop_mean, sigma_logpop, true).sum();
  vector<Type> basepop(exp(log_basepop));

  // prior for logit(Sx)
  PARAMETER_VECTOR(logit_sx);
  nll -= dnorm(logit_sx, logit_sx_mean, sigma_sx, true).sum();
  vector<Type> sx(invlogit(logit_sx));
  Map<Matrix<Type, Dynamic, Dynamic>> sx_mat(sx.data(), basepop.size() + 1, n_steps);

  // prior for log(fx)
  PARAMETER_VECTOR(log_fx);
  nll -= dnorm(log_fx, log_fx_mean, sigma_fx, true).sum();
  vector<Type> fx(exp(log_fx));
  Map<Matrix<Type, Dynamic, Dynamic>> fx_mat(fx.data(), fx_span, n_steps);

  // prior for gx
  PARAMETER_VECTOR(gx);
  nll -= dnorm(gx, gx_mean, sigma_gx, true).sum();
  Map<Matrix<Type, Dynamic, Dynamic>> gx_mat(gx.data(), basepop.size(), n_steps);

  // population projection
  matrix<Type> projpop(ccmpp<Type>(basepop, sx_mat, fx_mat, gx_mat,
				   srb, age_span, fx_idx-1));

  // likelihood for log census counts
  for(int i = 0; i < census_year_idx.size(); i++) {
    nll -= dnorm(vector<Type>(census_log_pop.col(i)),
  		 log(vector<Type>(projpop.col(census_year_idx[i] - 1))),
  		 sigma_logpop, true).sum();
  }

  vector<Type> population(Map<Matrix<Type, Dynamic, 1>>(projpop.data(), projpop.size(), 1));
  REPORT(population);

  return Type(nll);
}

#undef TMB_OBJECTIVE_PTR
#define TMB_OBJECTIVE_PTR this

#endif
