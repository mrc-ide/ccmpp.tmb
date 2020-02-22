
<!-- README.md is generated from README.Rmd. Please edit that file -->

# leapfrog

<!-- badges: start -->

[![Travis build
status](https://travis-ci.org/mrc-ide/leapfrog.svg?branch=master)](https://travis-ci.org/mrc-ide/leapfrog)
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

### TMB

Calculate a population projection in TMB.

``` r
library(TMB)

data <- list(basepop = as.vector(burkina.faso.females$baseline.pop.counts),
             sx = burkina.faso.females$survival.proportions[,1],
             fx = burkina.faso.females$fertility.rates[4:10, 1],
             srb = 1.05,
             age_span = 5,
             fx_idx = 4)
par <- list(theta = 0)

obj <- MakeADFun(data = c(model = "ccmpp_tmb", data), parameters = par,
                 DLL = "leapfrog_TMBExports", silent = TRUE)

obj$fn()
#> [1] 0
obj$report()
#> $projpop
#>  [1] 509479.592 338995.727 283642.516 252988.270 233696.092 196272.333 165551.320 143724.612 124993.657 105911.711  85786.913  64922.365  46416.989
#> [14]  29954.307  17193.530   7730.870   2965.314
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
