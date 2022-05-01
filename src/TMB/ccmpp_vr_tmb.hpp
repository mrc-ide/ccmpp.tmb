#ifndef CCMPP_VR_TMB_HPP
#define CCMPP_VR_TMB_HPP

#undef TMB_OBJECTIVE_PTR
#define TMB_OBJECTIVE_PTR obj

#include "../ccmpp.h"

template<class Type>
Type ccmpp_vr_tmb(objective_function<Type>* obj)
{

  std::cout << "ccmpp_vr_tmb" << std::endl;
  
  using Eigen::Matrix;
  using Eigen::Map;
  using Eigen::Dynamic;

  typedef Matrix<Type, Dynamic, Dynamic> MatrixXXt;
  typedef Map<Matrix<Type, Dynamic, 1>> MapVectorXt;
  typedef Map<MatrixXXt> MapMatrixXXt;

  
  DATA_VECTOR(log_basepop_mean);
  DATA_VECTOR(logit_sx_mean);
  DATA_VECTOR(log_fx_mean);
  DATA_VECTOR(gx_mean);
  DATA_VECTOR(srb);
  DATA_SCALAR(interval);
  DATA_INTEGER(n_periods);
  DATA_INTEGER(fx_idx);
  DATA_INTEGER(n_fx);

  // census data
  DATA_MATRIX(census_log_pop);
  DATA_IVECTOR(census_year_idx);

  // deaths data
  DATA_MATRIX(deaths_obs);

  // births data
  DATA_MATRIX(births_obs);

    
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
  MapMatrixXXt sx_mat(sx.data(), basepop.size() + 1, n_periods);

  // prior for log(fx)
  PARAMETER_VECTOR(log_fx);
  nll -= dnorm(log_fx, log_fx_mean, sigma_fx, true).sum();
  vector<Type> fx(exp(log_fx));
  MapMatrixXXt fx_mat(fx.data(), n_fx, n_periods);

  // prior for gx
  PARAMETER_VECTOR(gx);
  nll -= dnorm(gx, gx_mean, sigma_gx, true).sum();
  MapMatrixXXt gx_mat(gx.data(), basepop.size(), n_periods);

  // population projection
  PopulationProjection<Type> proj(ccmpp<Type>(basepop, sx_mat, fx_mat, gx_mat,
					      srb, interval, fx_idx-1));
  
  // likelihood for log census counts
  for(int i = 0; i < census_year_idx.size(); i++) {
    nll -= dnorm(vector<Type>(census_log_pop.col(i)),
  		 log(vector<Type>(proj.population.col(census_year_idx[i] - 1))),
  		 sigma_logpop, true).sum();
  }


  MatrixXXt proj_period_deaths(proj.period_deaths());
  vector<Type> period_deaths(MapVectorXt(proj_period_deaths.data(),
					 proj_period_deaths.size()));
  vector<Type> births(MapVectorXt(proj.births.data(),
				  proj.births.size()));

  vector<Type> deaths_obs_v(MapVectorXt(deaths_obs.data(),
					deaths_obs.size()));
  vector<Type> births_obs_v(MapVectorXt(births_obs.data(), births_obs.size()));
  
  
  // likelihood for deaths
  nll -= dpois(deaths_obs_v, period_deaths, true).sum();

  // likelihood for births
  nll -= dpois(births_obs_v, births, true).sum();


  DATA_INTEGER(calc_outputs);

  if(calc_outputs) {
    
    vector<Type> population(MapVectorXt(proj.population.data(),
					proj.population.size()));
    vector<Type> cohort_deaths(MapVectorXt(proj.cohort_deaths.data(),
					   proj.cohort_deaths.size()));
    vector<Type> infants(MapVectorXt(proj.infants.data(),
				     proj.infants.size()));
    vector<Type> migrations(MapVectorXt(proj.migrations.data(),
					proj.migrations.size()));
    REPORT(population);
    REPORT(cohort_deaths);
    REPORT(period_deaths);
    REPORT(births);
    REPORT(infants);
    REPORT(migrations);
    REPORT(sx);
    REPORT(fx);
    REPORT(gx);
  }
  
  return Type(nll);
}

#undef TMB_OBJECTIVE_PTR
#define TMB_OBJECTIVE_PTR this

#endif