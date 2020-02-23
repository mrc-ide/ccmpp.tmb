
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
library(TMB)

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

obj <- MakeADFun(data = c(model = "ccmpp_tmb", data),
                 parameters = par,
                 random = c("log_basepop", "logit_sx", "log_fx", "gx"),
                 DLL = "leapfrog_TMBExports", silent = TRUE)

obj$fn()
#> [1] 104.115
#> attr(,"logarithm")
#> [1] TRUE
obj$report()
#> $projpop
#>             [,1]       [,2]       [,3]       [,4]       [,5]       [,6]       [,7]       [,8]       [,9]      [,10]
#>  [1,] 396686.499 477417.777 529211.419 581397.698 665702.846 750439.738 856752.375 969635.830 1102622.52 1277069.05
#>  [2,] 289955.918 341766.000 409846.495 457466.241 518837.161 597997.156 684817.673 785631.991  900773.41 1032940.12
#>  [3,] 258520.347 279763.076 328662.394 389116.852 440753.634 501435.211 582566.171 668258.866  771638.46  886838.09
#>  [4,] 241039.307 242579.762 265918.376 312443.266 369326.677 420945.705 483616.057 563312.759  650180.97  766609.64
#>  [5,] 204541.639 217786.629 222697.849 247646.346 289095.989 344689.624 396686.692 458983.536  537878.41  648366.41
#>  [6,] 175079.698 184285.406 200470.416 208003.094 228702.687 270563.444 323794.020 375538.430  436541.46  535047.74
#>  [7,] 156196.174 159198.136 169784.342 188174.922 193095.777 214409.147 254679.904 306581.105  356636.09  435038.22
#>  [8,] 138100.880 142760.956 146533.937 158253.456 175425.696 180811.677 201340.584 240623.567  289760.54  355181.23
#>  [9,] 121712.151 125404.927 130575.737 135093.806 146294.807 163615.608 168976.354 188812.004  225413.61  287375.73
#> [10,] 101274.778 108594.313 112703.169 118379.314 122905.446 134275.953 151258.377 156788.059  174583.18  222005.13
#> [11,]  82002.221  87654.200  94781.776  99304.603 104646.287 110042.606 120936.054 137900.430  142661.67  169541.45
#> [12,]  62387.154  69316.599  74819.445  81725.442  85585.579  91770.734  97137.523 108211.452  123975.34  133219.62
#> [13,]  45941.505  50413.627  56689.055  61944.067  67789.544  72014.061  78088.061  84051.471   94271.10  109207.17
#> [14,]  31648.027  34011.750  37370.527  42783.186  47117.136  52388.182  56227.442  62507.814   68174.77   77458.96
#> [15,]  17399.755  20038.803  21867.980  24258.159  28243.704  31733.227  35890.657  39468.022   44906.03   49803.70
#> [16,]   8073.744   8156.944  10029.020  11214.299  12318.040  15074.452  17112.972  20272.904   22492.85   26542.43
#> [17,]   2003.091   3006.994   3421.031   4488.314   5105.533   5937.645   7491.702   9146.893   11275.33   12959.40

obj$report()$projpop[ , data$census_year_idx]
#>             [,1]       [,2]       [,3]       [,4]
#>  [1,] 581397.698 750439.738 969635.830 1277069.05
#>  [2,] 457466.241 597997.156 785631.991 1032940.12
#>  [3,] 389116.852 501435.211 668258.866  886838.09
#>  [4,] 312443.266 420945.705 563312.759  766609.64
#>  [5,] 247646.346 344689.624 458983.536  648366.41
#>  [6,] 208003.094 270563.444 375538.430  535047.74
#>  [7,] 188174.922 214409.147 306581.105  435038.22
#>  [8,] 158253.456 180811.677 240623.567  355181.23
#>  [9,] 135093.806 163615.608 188812.004  287375.73
#> [10,] 118379.314 134275.953 156788.059  222005.13
#> [11,]  99304.603 110042.606 137900.430  169541.45
#> [12,]  81725.442  91770.734 108211.452  133219.62
#> [13,]  61944.067  72014.061  84051.471  109207.17
#> [14,]  42783.186  52388.182  62507.814   77458.96
#> [15,]  24258.159  31733.227  39468.022   49803.70
#> [16,]  11214.299  15074.452  20272.904   26542.43
#> [17,]   4488.314   5937.645   9146.893   12959.40

fit <- nlminb(obj$par, obj$fn, obj$gr, control = list(trace = 1))
#>   0:     104.11496:  0.00000  0.00000  0.00000  0.00000
#>   1:     13.687871:  8.33846 0.739245 0.709793  2.53716
#>   2:    -22.160325:  7.39422 0.975503 0.808846  2.94291
#>   3:    -62.562982:  6.39082  2.33517  1.40934  5.07365
#>   4:    -71.343373:  7.64678  4.43986  2.71108  4.84033
#>   5:    -74.637770:  6.42608  5.62231  4.79727  4.12226
#>   6:    -77.418726:  6.80862  5.39044  4.83905  4.84942
#>   7:    -78.855491:  6.90137  4.54985  4.79827  4.73211
#>   8:    -78.930881:  6.84408  4.38611  4.57664  4.79047
#>   9:    -78.937169:  6.86256  4.37515  4.64532  4.79770
#>  10:    -78.937346:  6.86654  4.38633  4.62727  4.79822
#>  11:    -78.937409:  6.86384  4.38519  4.63303  4.79829
#>  12:    -78.937410:  6.86418  4.38419  4.63273  4.79838
#>  13:    -78.937410:  6.86416  4.38441  4.63271  4.79837
#>  14:    -78.937410:  6.86416  4.38441  4.63272  4.79837

fit              
#> $par
#> log_tau2_logpop     log_tau2_sx     log_tau2_fx     log_tau2_gx 
#>        6.864156        4.384406        4.632716        4.798370 
#> 
#> $objective
#> [1] -78.93741
#> 
#> $convergence
#> [1] 0
#> 
#> $iterations
#> [1] 14
#> 
#> $evaluations
#> function gradient 
#>       20       15 
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
