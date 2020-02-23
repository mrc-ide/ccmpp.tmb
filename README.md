
<!-- README.md is generated from README.Rmd. Please edit that file -->

# leapfrog

<!-- badges: start -->

[![Travis build
status](https://travis-ci.org/mrc-ide/leapfrog.svg?branch=master)](https://travis-ci.org/mrc-ide/leapfrog)
[![AppVeyor build
status](https://ci.appveyor.com/api/projects/status/github/mrc-ide/leapfrog?branch=master&svg=true)](https://ci.appveyor.com/project/mrc-ide/leapfrog)
[![Codecov test
coverage](https://codecov.io/gh/mrc-ide/leapfrog/branch/master/graph/badge.svg)](https://codecov.io/gh/mrc-ide/leapfrog?branch=master)
<!-- badges: end -->

Leapfrog is a multistate population projection model for demographic and
HIV epidemic estimation.

The name *leapfrog* is in honor of
[Professor](https://blogs.lshtm.ac.uk/alumni/2018/07/16/obituary-professor-basia-zaba/)
Basia
[Zaba](https://translate.google.co.uk/#view=home&op=translate&sl=pl&tl=en&text=%C5%BBaba).

## Installation

Install the development version from
[GitHub](https://github.com/mrc-ide/leapfrog) via devtools:

``` r
# install.packages("devtools")
devtools::install_github("mrc-ide/leapfrog")
```

## Example

Construct a sparse Leslie matrix:

``` r
library(leapfrog)
library(popReconstruct)
#> Loading required package: coda

data(burkina_faso_females)

make_leslie_matrixR(sx = burkina.faso.females$survival.proportions[,1],
                    fx = burkina.faso.females$fertility.rates[4:10, 1],
                    srb = 1.05,
                    age_span = 5,
                    fx_idx = 4)
#> 17 x 17 sparse Matrix of class "dgCMatrix"
#>                                                                                                                                                  
#>  [1,] .         .         0.2090608 0.5400452 0.6110685 0.5131988 0.3952854 0.2440665 0.1012326 0.01816255 .        .         .         .        
#>  [2,] 0.8782273 .         .         .         .         .         .         .         .         .          .        .         .         .        
#>  [3,] .         0.9713785 .         .         .         .         .         .         .         .          .        .         .         .        
#>  [4,] .         .         0.9730318 .         .         .         .         .         .         .          .        .         .         .        
#>  [5,] .         .         .         0.9577709 .         .         .         .         .         .          .        .         .         .        
#>  [6,] .         .         .         .         0.9481755 .         .         .         .         .          .        .         .         .        
#>  [7,] .         .         .         .         .         0.9460075 .         .         .         .          .        .         .         .        
#>  [8,] .         .         .         .         .         .         0.9393766 .         .         .          .        .         .         .        
#>  [9,] .         .         .         .         .         .         .         0.9258789 .         .          .        .         .         .        
#> [10,] .         .         .         .         .         .         .         .         0.9052283 .          .        .         .         .        
#> [11,] .         .         .         .         .         .         .         .         .         0.87537666 .        .         .         .        
#> [12,] .         .         .         .         .         .         .         .         .         .          0.832338 .         .         .        
#> [13,] .         .         .         .         .         .         .         .         .         .          .        0.7736165 .         .        
#> [14,] .         .         .         .         .         .         .         .         .         .          .        .         0.6966118 .        
#> [15,] .         .         .         .         .         .         .         .         .         .          .        .         .         0.5928803
#> [16,] .         .         .         .         .         .         .         .         .         .          .        .         .         .        
#> [17,] .         .         .         .         .         .         .         .         .         .          .        .         .         .        
#>                                    
#>  [1,] .         .         .        
#>  [2,] .         .         .        
#>  [3,] .         .         .        
#>  [4,] .         .         .        
#>  [5,] .         .         .        
#>  [6,] .         .         .        
#>  [7,] .         .         .        
#>  [8,] .         .         .        
#>  [9,] .         .         .        
#> [10,] .         .         .        
#> [11,] .         .         .        
#> [12,] .         .         .        
#> [13,] .         .         .        
#> [14,] .         .         .        
#> [15,] .         .         .        
#> [16,] 0.4547571 .         .        
#> [17,] .         0.3181678 0.2099861
```

Simulate a cohort component population projection:

``` r
pop_proj <- ccmppR(basepop = as.numeric(burkina.faso.females$baseline.pop.counts),
                   sx = burkina.faso.females$survival.proportions,
                   fx = burkina.faso.females$fertility.rates[4:10, ],
                   gx = burkina.faso.females$migration.proportions,
                   srb = rep(1.05, ncol(burkina.faso.females$survival.proportions)),
                   age_span = 5,
                   fx_idx = 4)
pop_proj[ , c(1, 2, ncol(pop_proj))]
#>         [,1]       [,2]       [,3]
#>  [1,] 386000 496963.688 1369041.17
#>  [2,] 292000 338995.727 1088715.23
#>  [3,] 260000 283642.516  952860.73
#>  [4,] 244000 246278.270  846073.20
#>  [5,] 207000 221576.949  719894.38
#>  [6,] 175000 186062.343  572001.86
#>  [7,] 153000 156791.159  458905.67
#>  [8,] 135000 136059.686  379925.83
#>  [9,] 117000 118338.831  309642.33
#> [10,]  98000 100304.139  208006.24
#> [11,]  78000  81282.772  154298.67
#> [12,]  60000  63137.000  114066.08
#> [13,]  43000  46416.989   90879.78
#> [14,]  29000  29954.307   65876.04
#> [15,]  17000  17193.530   41985.79
#> [16,]   8000   7730.870   22044.43
#> [17,]   2000   2965.314   11332.85
```

### TMB

Calculate a population projection in TMB.

``` r

log_basepop_mean <- as.vector(log(burkina.faso.females$baseline.pop.counts))
logit_sx_mean <- as.vector(qlogis(burkina.faso.females$survival.proportions))
log_fx_mean <- as.vector(log(burkina.faso.females$fertility.rates[4:10, ]))
gx_mean <- as.vector(burkina.faso.females$migration.proportions)
  
data <- list(log_basepop_mean = log_basepop_mean,
             logit_sx_mean = logit_sx_mean,
             log_fx_mean = log_fx_mean,
             gx_mean = gx_mean,
             srb = rep(1.05, ncol(burkina.faso.females$survival.proportions)),
             age_span = 5,
             n_steps = ncol(burkina.faso.females$survival.proportions),
             fx_idx = 4L,
             fx_span = 7L,
             census_log_pop = log(burkina.faso.females$census.pop.counts),
             census_year_idx = c(4L, 6L, 8L, 10L))
par <- list(log_tau2_logpop = 0,
            log_tau2_sx = 0,
            log_tau2_fx = 0,
            log_tau2_gx = 0,
            log_basepop = log_basepop_mean,
            logit_sx = logit_sx_mean,
            log_fx = log_fx_mean,
            gx = gx_mean)

obj <- make_tmb_obj(data, par)

obj$fn()
#> [1] 110.8335
#> attr(,"logarithm")
#> [1] TRUE
obj$report()
#> $projpop
#>             [,1]       [,2]       [,3]       [,4]       [,5]       [,6]       [,7]       [,8]       [,9]      [,10]
#>  [1,] 394264.995 487784.810 540018.138 586299.168 677858.682 753003.656 861154.111 962489.176 1082521.93 1252978.16
#>  [2,] 289890.011 343753.721 419737.234 459242.300 524010.031 598045.584 682204.205 775198.946  889000.40 1008185.99
#>  [3,] 259913.272 281846.241 332394.018 394553.653 444629.010 503462.586 583032.285 657974.445  754616.19  869072.03
#>  [4,] 242404.134 245840.891 269380.587 315992.069 375192.263 422558.078 485824.125 557023.454  627252.67  753945.02
#>  [5,] 206131.453 220537.945 226062.827 250625.530 292074.372 346908.252 395521.809 454997.405  515982.58  641580.04
#>  [6,] 176193.066 186484.029 202728.741 210429.292 230917.023 272236.861 323883.964 371919.407  422073.88  528990.03
#>  [7,] 156898.496 160413.779 171447.436 189557.388 194666.360 215524.244 255247.597 304938.785  345365.10  434418.70
#>  [8,] 138681.103 143309.959 147280.362 159122.133 176265.748 181456.243 201702.716 240261.828  282397.50  354780.52
#>  [9,] 121749.084 125667.569 130762.016 135284.233 146745.809 163936.098 169226.180 188471.502  221170.78  287730.98
#> [10,] 101069.975 108187.757 112729.186 118315.492 122752.017 134372.105 151354.749 156718.080  171478.99  223084.83
#> [11,]  81809.195  86979.407  94194.089  99280.765 104197.575 109659.465 120418.556 137829.574  140622.16  170540.89
#> [12,]  62040.117  68811.432  74168.911  81464.594  85510.551  91618.592  96587.092 108025.671  123468.54  133830.94
#> [13,]  45587.954  49977.998  56352.733  61818.277  67800.584  72442.566  78173.743  84186.123   94340.20  109726.37
#> [14,]  31431.944  33653.117  37105.738  42765.853  47225.246  52675.517  56657.361  62806.965   68398.72   77759.38
#> [15,]  17309.377  19867.782  21754.724  24274.364  28369.987  32049.045  36113.452  39847.691   45027.71   50071.95
#> [16,]   8026.650   8119.712   9975.319  11286.657  12350.756  15250.511  17232.559  20411.382   22453.53   26561.60
#> [17,]   2001.066   2992.425   3412.636   4538.638   5141.684   5972.196   7542.503   9158.649   11226.63   12697.11

obj$report()$projpop[ , data$census_year_idx]
#>             [,1]       [,2]       [,3]       [,4]
#>  [1,] 586299.168 753003.656 962489.176 1252978.16
#>  [2,] 459242.300 598045.584 775198.946 1008185.99
#>  [3,] 394553.653 503462.586 657974.445  869072.03
#>  [4,] 315992.069 422558.078 557023.454  753945.02
#>  [5,] 250625.530 346908.252 454997.405  641580.04
#>  [6,] 210429.292 272236.861 371919.407  528990.03
#>  [7,] 189557.388 215524.244 304938.785  434418.70
#>  [8,] 159122.133 181456.243 240261.828  354780.52
#>  [9,] 135284.233 163936.098 188471.502  287730.98
#> [10,] 118315.492 134372.105 156718.080  223084.83
#> [11,]  99280.765 109659.465 137829.574  170540.89
#> [12,]  81464.594  91618.592 108025.671  133830.94
#> [13,]  61818.277  72442.566  84186.123  109726.37
#> [14,]  42765.853  52675.517  62806.965   77759.38
#> [15,]  24274.364  32049.045  39847.691   50071.95
#> [16,]  11286.657  15250.511  20411.382   26561.60
#> [17,]   4538.638   5972.196   9158.649   12697.11

fit <- nlminb(obj$par, obj$fn, obj$gr, control = list(trace = 1))
#>   0:     110.83349:  0.00000  0.00000  0.00000  0.00000
#>   1:     24.892728:  3.47909 0.328263 0.303597  1.92250
#>   2:    -39.081896:  5.44273  1.52064  1.06743  5.10666
#>   3:    -56.306496:  6.80894  2.66742  1.68368  4.98032
#>   4:    -56.845045:  6.34157  3.88053  2.61444  5.99075
#>   5:    -64.797080:  6.63179  3.87162  2.76071  5.10270
#>   6:    -66.807665:  6.84558  4.12277  3.61226  5.34850
#>   7:    -68.296168:  6.65362  4.16468  4.52944  5.22802
#>   8:    -68.630793:  6.74695  4.37864  5.18194  5.02382
#>   9:    -68.736453:  6.68438  4.50870  4.91524  5.05102
#>  10:    -68.738063:  6.69140  4.51487  4.94850  5.05221
#>  11:    -68.738076:  6.69265  4.51519  4.94882  5.05129
#>  12:    -68.738077:  6.69239  4.51545  4.94908  5.05136
#>  13:    -68.738077:  6.69241  4.51543  4.94903  5.05137

fit              
#> $par
#> log_tau2_logpop     log_tau2_sx     log_tau2_fx     log_tau2_gx 
#>        6.692407        4.515433        4.949035        5.051373 
#> 
#> $objective
#> [1] -68.73808
#> 
#> $convergence
#> [1] 0
#> 
#> $iterations
#> [1] 13
#> 
#> $evaluations
#> function gradient 
#>       18       14 
#> 
#> $message
#> [1] "relative convergence (4)"
```

## Development notes

  - TMB model code and testing are implemented following templates from
    the [`TMBtools`](https://github.com/mlysy/TMBtools) package with
    guidance for package development with both TMB models and Rcpp code.
      - To add a new TMB model, save the model template in the `src/TMB`
        with extension `.pp`. The model name must match the file name.
        The signature is slightly different – see other `.hpp` files for
        example.
      - Call `TMBtools::export_models()` to export the new TMB model to
        the meta-model list.
      - When constructing the objective function with `TMB::MakeADFun`,
        use `DLL= "leapfrog_TMBExports"` and add an additional value
        `model = "<model_name>"` to the `data` list.
