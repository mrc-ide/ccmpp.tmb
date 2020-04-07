#ifndef CCMPP_H
#define CCMPP_H

#include <Eigen/Dense>
#include <Eigen/Sparse>


template <typename Type>
Eigen::SparseMatrix<Type>
make_leslie_matrix(const Eigen::Array<Type, Eigen::Dynamic, 1>& sx,
                   const Eigen::Array<Type, Eigen::Dynamic, 1>& fx,
                   const Type srb,
                   const Type interval,
                   const int fx_idx) {
  
  Type fert_k = sx[0] * 0.5 * interval / (1.0 + srb);

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

template <typename Type>
Eigen::Matrix<Type, Eigen::Dynamic, Eigen::Dynamic>
ccmpp_leslie(const Eigen::Matrix<Type, Eigen::Dynamic, 1>& basepop,
	     const Eigen::Array<Type, Eigen::Dynamic, Eigen::Dynamic>& sx,
	     const Eigen::Array<Type, Eigen::Dynamic, Eigen::Dynamic>& fx,
	     const Eigen::Array<Type, Eigen::Dynamic, Eigen::Dynamic>& gx,
	     const Eigen::Array<Type, Eigen::Dynamic, 1>& srb,
	     const Type interval,
	     const int fx_idx) {

  int nsteps(sx.cols());
  Eigen::Matrix<Type, Eigen::Dynamic, Eigen::Dynamic> population(basepop.rows(), nsteps + 1);

  population.col(0) = basepop;
  for(int step = 0; step < nsteps; step++) {
    Eigen::Matrix<Type, Eigen::Dynamic, 1> migrants(population.col(step).array() *
						    gx.col(step));
    Eigen::SparseMatrix<Type> leslie(make_leslie_matrix<Type>(sx.col(step), fx.col(step), srb[step], interval, fx_idx));
    population.col(step + 1) = leslie * (population.col(step) + 0.5 * migrants) + 0.5 * migrants;
  }

  return population;
}

template <typename Type>
class PopulationProjection {

  typedef Eigen::Matrix<Type, Eigen::Dynamic, Eigen::Dynamic> MatrixXXT;
  typedef Eigen::Array<Type, Eigen::Dynamic, Eigen::Dynamic> ArrayXXT;
  typedef Eigen::Array<Type, 1, Eigen::Dynamic> Array1XT;

 public: 

  const int n_ages;
  const int n_periods;
  const int n_fx;    // number of age groups eligible for fertility
  const int fx_idx;  // first age index eligible for fertility
  const Type interval;

  const ArrayXXT sx;
  const ArrayXXT fx;
  const ArrayXXT gx;
  const Array1XT srb;
    
  MatrixXXT population;
  MatrixXXT cohort_deaths;
  MatrixXXT births;
  Eigen::Matrix<Type, 1, Eigen::Dynamic> infants;
  MatrixXXT migrations;
    
 PopulationProjection(const int n_ages,
		      const int n_periods,
		      const int n_fx,
		      const int fx_idx,
		      const Type interval,
		      const Eigen::Matrix<Type, Eigen::Dynamic, 1>& basepop,
		      const Eigen::Array<Type, Eigen::Dynamic, Eigen::Dynamic>& sx,
		      const Eigen::Array<Type, Eigen::Dynamic, Eigen::Dynamic>& fx,
		      const Eigen::Array<Type, Eigen::Dynamic, Eigen::Dynamic>& gx,
		      const Eigen::Array<Type, Eigen::Dynamic, 1>& srb) :
    n_ages{ n_ages },
    n_periods{ n_periods },
    n_fx{ n_fx },
    fx_idx{ fx_idx },
    interval{ interval },
    sx{ sx },
    fx{ fx },
    gx{ gx },
    srb{ srb },
    population{ MatrixXXT(n_ages, n_periods + 1) },
    cohort_deaths{ MatrixXXT(n_ages+1, n_periods) },
    births{ MatrixXXT(n_fx, n_periods) },
    infants{ Eigen::Matrix<Type, 1, Eigen::Dynamic>(n_periods) },
    migrations{ MatrixXXT(n_ages, n_periods) }
    {
      population.col(0) = basepop;
    };

    void step_projection(int step);

    MatrixXXT period_deaths();
  
};

template <typename Type>
void PopulationProjection<Type>::step_projection(int step) {

  typedef Eigen::Map<Eigen::Array<Type, Eigen::Dynamic, 1> > MapArrayXT;
  typedef Eigen::Map<const Eigen::Array<Type, Eigen::Dynamic, 1> > MapConstArrayXT;

  MapConstArrayXT sx_t(sx.col(step).data(), n_ages + 1);
  MapConstArrayXT fx_t(fx.col(step).data(), fx.rows());
  MapConstArrayXT gx_t(gx.col(step).data(), n_ages);
  
  MapArrayXT population_t(population.col(step+1).data(), population.rows());
  MapArrayXT migrations_t(migrations.col(step).data(), migrations.rows());
  MapArrayXT cohort_deaths_t(cohort_deaths.col(step).data(), cohort_deaths.rows());
  MapArrayXT births_t(births.col(step).data(), births.rows());
  MapArrayXT infants_t(infants.col(step).data(), infants.rows());

  population_t = population.col(step);
  
  migrations_t = population_t * gx_t;
  population_t += 0.5 * migrations_t;
  
  cohort_deaths_t.segment(1, n_ages) = population_t * (1.0 - sx_t.segment(1, n_ages));
  births_t = 0.5 * interval * fx_t * population_t.segment(fx_idx, n_fx);

  Type open_age_survivors = population_t(n_ages-1) - cohort_deaths_t(n_ages);
  for(int age = n_ages-1; age > 0; age--) {
    population_t(age) = population_t(age-1) - cohort_deaths_t(age);
  }
  population_t(n_ages-1) += open_age_survivors;
  
  births_t += 0.5 * interval * fx_t * population_t.segment(fx_idx, n_fx);
  infants_t = births_t.sum() / (1.0 + srb(step));
  cohort_deaths_t(0) = infants_t(0) * (1.0 - sx_t(0));
  population_t(0) = infants_t(0) - cohort_deaths_t(0);
  
  population_t += 0.5 * migrations_t;
}

template <typename Type>
Eigen::Matrix<Type, Eigen::Dynamic, Eigen::Dynamic> PopulationProjection<Type>::period_deaths() {

  typedef Eigen::Matrix<Type, Eigen::Dynamic, Eigen::Dynamic> MatrixXXT;
  
  MatrixXXT period_deaths(0.5 * cohort_deaths.topRows(n_ages));
  period_deaths += 0.5 * cohort_deaths.bottomRows(n_ages);
  period_deaths.row(0) += 0.5 * cohort_deaths.row(0);
  period_deaths.row(n_ages-1) += 0.5 * cohort_deaths.row(n_ages);

  return period_deaths;
}

  
template <typename Type>
PopulationProjection<Type>
ccmpp(const Eigen::Matrix<Type, Eigen::Dynamic, 1>& basepop,
      const Eigen::Array<Type, Eigen::Dynamic, Eigen::Dynamic>& sx,
      const Eigen::Array<Type, Eigen::Dynamic, Eigen::Dynamic>& fx,
      const Eigen::Array<Type, Eigen::Dynamic, Eigen::Dynamic>& gx,
      const Eigen::Array<Type, Eigen::Dynamic, 1>& srb,
      const Type interval,
      const int fx_idx) {

  int n_periods(sx.cols());
  int n_ages(basepop.rows());
  int n_fx(fx.rows());

  PopulationProjection<Type> proj(n_ages, n_periods, n_fx, fx_idx, interval,
				  basepop, sx, fx, gx, srb);

  for(int step = 0; step < n_periods; step++) {
    proj.step_projection(step);
  }

  return proj;
}

#endif
