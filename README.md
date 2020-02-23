
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

log_basepop_mean <- as.vector(log(burkina.faso.females$baseline.pop.counts))
logit_sx_mean <- as.vector(qlogis(burkina.faso.females$survival.proportions))
log_fx_mean <- as.vector(log(burkina.faso.females$fertility.rates[4:10, ]))
  
data <- list(log_basepop_mean = log_basepop_mean,
             logit_sx_mean = logit_sx_mean,
             log_fx_mean = log_fx_mean,
             srb = rep(1.05, ncol(burkina.faso.females$survival.proportions)),
             age_span = 5,
             n_steps = ncol(burkina.faso.females$survival.proportions),
             fx_idx = 4L,
             fx_span = 7L,
             census_log_pop = log(burkina.faso.females$census.pop.counts),
             census_year_idx = c(4L, 6L, 8L, 10L))
par <- list(log_sigma_logpop = 0,
            log_basepop = log_basepop_mean,
            log_sigma_sx = 0,
            logit_sx = logit_sx_mean,
            log_sigma_fx = 0,
            log_fx = log_fx_mean)

obj <- MakeADFun(data = c(model = "ccmpp_tmb", data),
                 parameters = par,
                 random = c("log_basepop", "logit_sx", "log_fx"),
                 DLL = "leapfrog_TMBExports", silent = TRUE)

obj$fn()
#> [1] 76.49551
#> attr(,"logarithm")
#> [1] TRUE
obj$report()
#> $sigma_logpop
#> [1] 1
#> 
#> $projpop
#>             [,1]       [,2]       [,3]       [,4]       [,5]       [,6]       [,7]        [,8]       [,9]      [,10]
#>  [1,] 347782.760 422275.746 486176.073 553630.861 643241.384 749527.021 872105.898 1002538.757 1157315.09 1329574.48
#>  [2,] 254161.346 304952.425 376472.917 438632.305 504850.232 591655.187 692887.659  808550.633  935229.19 1087610.77
#>  [3,] 220205.218 246858.631 297242.777 367966.096 429803.533 495749.540 581956.515  682464.667  797453.48  923569.56
#>  [4,] 206554.356 214240.626 240961.286 290917.898 360958.696 422472.782 488073.329  573701.778  673632.47  788069.29
#>  [5,] 178714.429 197781.529 206189.417 232882.744 282187.437 351214.816 412139.497  477154.347  561991.55  661118.65
#>  [6,] 157775.800 169400.888 188640.263 197673.212 224251.005 272806.965 340597.559  400752.835  465145.55  549098.49
#>  [7,] 145423.189 149223.079 161216.442 180490.333 189996.688 216425.951 264174.732  330733.254  390175.58  453945.72
#>  [8,] 132228.607 136591.752 141102.065 153345.410 172571.234 182487.830 208665.070  255532.709  320837.93  379506.83
#>  [9,] 120515.538 122422.397 127471.211 132613.197 145029.442 164131.897 174385.318  200201.260  246063.72  309921.22
#> [10,] 104223.909 109128.908 111909.708 117574.278 123288.707 135800.457 154648.144  165173.214  190514.79  235117.86
#> [11,]  86795.638  91323.184  96748.104 100324.472 106509.637 112725.294 125204.541  143616.594  154344.28  178974.53
#> [12,]  66175.010  72455.873  77300.956  83080.447  87282.946  93858.249 100464.102  112710.761  130408.74  141140.85
#> [13,]  48761.610  51445.271  57387.504  62289.273  68108.781  72666.055  79431.088   86188.115   97832.37  114304.63
#> [14,]  33014.259  34348.129  36935.767  42212.373  46700.666  52151.802  56669.823   63291.840   69719.96   80121.44
#> [15,]  17396.685  19979.381  21279.221  23456.308  27530.855  31172.832  35729.009   39721.415   45451.30   50795.72
#> [16,]   8039.435   7965.238   9683.726  10662.264  11894.666  14627.015  16866.585   20189.446   22717.25   26826.78
#> [17,]   2001.614   2984.257   3297.485   4276.232   4862.009   5740.497   7278.337    9017.257   11222.64   13042.68

obj$report()$projpop[ , data$census_year_idx]
#>             [,1]       [,2]        [,3]       [,4]
#>  [1,] 553630.861 749527.021 1002538.757 1329574.48
#>  [2,] 438632.305 591655.187  808550.633 1087610.77
#>  [3,] 367966.096 495749.540  682464.667  923569.56
#>  [4,] 290917.898 422472.782  573701.778  788069.29
#>  [5,] 232882.744 351214.816  477154.347  661118.65
#>  [6,] 197673.212 272806.965  400752.835  549098.49
#>  [7,] 180490.333 216425.951  330733.254  453945.72
#>  [8,] 153345.410 182487.830  255532.709  379506.83
#>  [9,] 132613.197 164131.897  200201.260  309921.22
#> [10,] 117574.278 135800.457  165173.214  235117.86
#> [11,] 100324.472 112725.294  143616.594  178974.53
#> [12,]  83080.447  93858.249  112710.761  141140.85
#> [13,]  62289.273  72666.055   86188.115  114304.63
#> [14,]  42212.373  52151.802   63291.840   80121.44
#> [15,]  23456.308  31172.832   39721.415   50795.72
#> [16,]  10662.264  14627.015   20189.446   26826.78
#> [17,]   4276.232   5740.497    9017.257   13042.68

fit <- nlminb(obj$par, obj$fn, obj$gr, control = list(trace = 1))
#>   0:     76.495511:  0.00000  0.00000  0.00000
#>   1:    -60.996973: -3.99521 -0.127793 -0.148294
#>   2:    -72.000004: -4.04123 -0.518112 -0.222678
#>   3:    -73.931245: -4.17308 -0.858251 -0.386754
#>   4:    -77.643339: -4.26629 -0.650416 -0.715565
#>   5:    -81.364317: -4.47036 -0.752700 -1.48231
#>   6:    -82.952947: -5.24041 -0.692425 -1.69060
#>   7:    -83.079725: -5.41612 -0.723707 -1.81217
#>   8:    -83.097280: -5.47491 -0.713803 -1.88182
#>   9:    -83.098353: -5.50013 -0.714740 -1.87653
#>  10:    -83.098480: -5.51036 -0.714671 -1.87184
#>  11:    -83.098481: -5.51057 -0.714618 -1.87143
#>  12:    -83.098481: -5.51054 -0.714612 -1.87139

fit              
#> $par
#> log_sigma_logpop     log_sigma_sx     log_sigma_fx 
#>       -5.5105402       -0.7146123       -1.8713949 
#> 
#> $objective
#> [1] -83.09848
#> 
#> $convergence
#> [1] 0
#> 
#> $iterations
#> [1] 12
#> 
#> $evaluations
#> function gradient 
#>       15       13 
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
