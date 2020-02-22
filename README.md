
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
                   srb = rep(1.05, ncol(burkina.faso.females$survival.proportions)),
                   age_span = 5,
                   fx_idx = 4)
pop_proj[ , c(1, 2, ncol(pop_proj))]
#>         [,1]       [,2]       [,3]
#>  [1,] 386000 509479.592 1626384.22
#>  [2,] 292000 338995.727 1327935.93
#>  [3,] 260000 283642.516 1134044.00
#>  [4,] 244000 252988.270  960417.99
#>  [5,] 207000 233696.092  798458.66
#>  [6,] 175000 196272.333  657179.40
#>  [7,] 153000 165551.320  546359.28
#>  [8,] 135000 143724.612  462499.51
#>  [9,] 117000 124993.657  375389.32
#> [10,]  98000 105911.711  261561.20
#> [11,]  78000  85786.913  205876.07
#> [12,]  60000  64922.365  166899.67
#> [13,]  43000  46416.989  135244.35
#> [14,]  29000  29954.307   93073.59
#> [15,]  17000  17193.530   56542.05
#> [16,]   8000   7730.870   28184.57
#> [17,]   2000   2965.314   13474.58
```

### TMB

Calculate a population projection in TMB.

``` r
library(TMB)

data <- list(basepop = as.vector(burkina.faso.females$baseline.pop.counts),
             sx = burkina.faso.females$survival.proportions,
             fx = burkina.faso.females$fertility.rates[4:10, ],
             srb = rep(1.05, ncol(burkina.faso.females$survival.proportions)),
             age_span = 5,
             fx_idx = 4,
             census_log_pop = log(burkina.faso.females$census.pop.counts),
             census_year_idx = c(3L, 5L, 7L, 9L))
par <- list(log_sigma_logpop = 0)

obj <- MakeADFun(data = c(model = "ccmpp_tmb", data), parameters = par,
                 DLL = "leapfrog_TMBExports", silent = TRUE)

obj$fn()
#> [1] 63.62373
obj$report()$projpop[ , data$census_year_idx]
#>             [,1]       [,2]        [,3]       [,4]
#>  [1,] 590983.383 769037.265 1062070.413 1412608.05
#>  [2,] 455588.541 607495.734  836783.769 1148348.26
#>  [3,] 330447.405 523593.621  696452.594  971845.28
#>  [4,] 276888.315 436916.491  587359.242  813558.11
#>  [5,] 243521.678 313772.287  502163.328  672594.53
#>  [6,] 222929.762 257771.576  412421.185  559824.69
#>  [7,] 186817.050 224462.971  293817.254  475480.10
#>  [8,] 156560.469 203979.472  239926.467  388578.30
#>  [9,] 134131.817 168100.638  206082.330  273716.47
#> [10,] 114257.447 136831.575  182847.619  219114.33
#> [11,]  93850.093 112080.451  145188.432  182463.30
#> [12,]  72507.026  89126.154  111568.392  154250.74
#> [13,]  51181.546  65935.254   83590.708  113547.90
#> [14,]  33064.417  43559.414   57967.690   77517.04
#> [15,]  18217.493  24107.295   34437.225   47803.42
#> [16,]   8046.969  10420.995   15660.896   23559.73
#> [17,]   3186.973   4008.592    6246.027   10695.60

fit <- nlminb(obj$par, obj$fn, obj$gr, control = list(trace = 1))
#>   0:     63.623734:  0.00000
#>   1:     3.8811528: -1.00000
#>   2:    -7.0773252: -1.24124
#>   3:    -17.311167: -1.72372
#>   4:    -17.362466: -1.67589
#>   5:    -17.379774: -1.69154
#>   6:    -17.379791: -1.69206
#>   7:    -17.379791: -1.69205
#>   8:    -17.379791: -1.69205

fit              
#> $par
#> log_sigma_logpop 
#>        -1.692054 
#> 
#> $objective
#> [1] -17.37979
#> 
#> $convergence
#> [1] 0
#> 
#> $iterations
#> [1] 8
#> 
#> $evaluations
#> function gradient 
#>       11        8 
#> 
#> $message
#> [1] "both X-convergence and relative convergence (5)"
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
