
<!-- README.md is generated from README.Rmd. Please edit that file -->

# R/`InterXShift`

<!-- badges: start -->

[![R-CMD-check](https://github.com/blind-contours/InterXShift/workflows/R-CMD-check/badge.svg)](https://github.com/blind-contours/InterXShift/actions)
[![Coverage
Status](https://img.shields.io/codecov/c/github/blind-contours/InterXShift/master.svg)](https://codecov.io/github/blind-contours/InterXShift?branch=master)
[![CRAN](https://www.r-pkg.org/badges/version/InterXShift)](https://www.r-pkg.org/pkg/InterXShift)
[![CRAN
downloads](https://cranlogs.r-pkg.org/badges/InterXShift)](https://CRAN.R-project.org/package=InterXShift)
[![CRAN total
downloads](http://cranlogs.r-pkg.org/badges/grand-total/InterXShift)](https://CRAN.R-project.org/package=InterXShift)
[![Project Status: Active – The project has reached a stable, usable
state and is being actively
developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![MIT
license](https://img.shields.io/badge/license-MIT-brightgreen.svg)](https://opensource.org/licenses/MIT)
<!-- [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.4070042.svg)](https://doi.org/10.5281/zenodo.4070042) -->
<!-- [![DOI](https://joss.theoj.org/papers/10.21105/joss.02447/status.svg)](https://doi.org/10.21105/joss.02447) -->
<!-- badges: end -->

> Interaction Identification and Estimation using Data-Adaptive
> Stochastic Interventions **Authors:** [David
> McCoy](https://davidmccoy.org)

------------------------------------------------------------------------

## What’s `InterXshift`?

The `InterXshift` R package offers an approach which identifies and
estimates the impact interactions in a mixed exposure on an outcome. We
define interaction as the counterfactual mean of the outcome under
stochastic interventions of two exposures compared to the additive
counterfactual mean of the two expowures intervened on indepdentently.
These interventions or exposure changes depend on naturally observed
values, as described in past literature (Dı́az and van der Laan 2012;
Haneuse and Rotnitzky 2013).

`InterXshift` builds on work described in (McCoy et al. 2023). However
instead of identifying interactions through an semi-parametric
definition of an F-statistics and then estimating our interaction target
parameter using CV-TMLE pooled across exposure sets, we provide a more
streamlined approach. In this package, we identify interactions through
g-computation first - evaluating the expected outcome under joint shift
compared to the sum of individual shifts using Super Learner. We then
rank these estimates as the highest sets of synergy and antagonism. We
then use CV-TMLE and pool within the ranks.

The package ensures robustness by employing a k-fold cross-validation
framework. This framework helps in estimating a data-adaptive parameter,
which is the stochastic shift target parameters for the exposure sets
identified as having synergy or antagonism. The process begins by
partitioning the data into parameter-generating and estimation samples.
In the parameter-generating sample, we identify our ranks of
antogonistic and synergistic exposure sets through a machine learning
g-computation framework. In the estimation sample we then estimate our
interaction target parameter using the doubly robust estimator TMLE to
ensure asymptotic efficiency which allows us to construct confidence
intervals for our estimates (unlike the g-comp method).

By using InterXshift, users get access to a tool that offers both k-fold
specific and aggregated results for the top synergistic and antagonistic
relationships, ensuring that researchers can glean the most information
from their data. For a more in-depth exploration, there’s an
accompanying vignette.

To utilize the package, users need to provide vectors for exposures,
covariates, and outcomes. They also specify the respective $\delta$ for
each exposure (indicating the degree of shift) and if this delta should
be adaptive in response to positivity violations. The `top_n` parameter
defines the top number of synergistic, antagonistic, positive and
negative ranked impacts to estiamte. A detailed guide is provided in the
vignette. With these inputs, `InterXshift` processes the data and
delivers tables showcasing fold-specific results and aggregated
outcomes, allowing users to glean insights effectively.

`InterXshift` also incorporates features from the `sl3` package (Coyle,
Hejazi, Malenica, et al. 2022), facilitating ensemble machine learning
in the estimation process. If the user does not specify any stack
parameters, `SuperNOVA` will automatically create an ensemble of machine
learning algorithms that strike a balance between flexibility and
computational efficiency.

------------------------------------------------------------------------

## Installation

*Note:* Because the `InterXshift` package (currently) depends on `sl3`
that allows ensemble machine learning to be used for nuisance parameter
estimation and `sl3` is not on CRAN the `InterXshift` package is not
available on CRAN and must be downloaded here.

There are many depedencies for `InterXshift` so it’s easier to break up
installation of the various packages to ensure proper installation.

First install the basis estimators used in the data-adaptive variable
discovery of the exposure and covariate space:

``` r
install.packages("earth")
install.packages("hal9001")
```

`InterXshift` uses the `sl3` package to build ensemble machine learners
for each nuisance parameter. We have to install off the development
branch, first download these two packages for `sl3`

``` r
install.packages(c("ranger", "arm", "xgboost", "nnls"))
```

Now install `sl3` on devel:

``` r
remotes::install_github("tlverse/sl3@devel")
```

Make sure `sl3` installs correctly then install `InterXshift`

``` r
remotes::install_github("blind-contours/InterXshift@main")
```

`InterXshift` has some other miscellaneous dependencies that are used in
the examples as well as in the plotting functions.

``` r
install.packages(c("kableExtra", "hrbrthemes", "viridis"))
```

------------------------------------------------------------------------

## Example

To illustrate how `InterXshift` may be used to ascertain the effect of a
mixed exposure, consider the following example:

``` r
library(InterXshift)
library(devtools)
#> Loading required package: usethis
library(kableExtra)
library(sl3)

set.seed(429153)
# simulate simple data
n_obs <- 10000
```

We will directly use synthetic data from the NIEHS used to test new
mixture methods. This data has built in strong positive and negative
marginal effects and certain interactions. Found here:
<https://github.com/niehs-prime/2015-NIEHS-MIxtures-Workshop>

``` r
data("NIEHS_data_1", package = "SuperNOVA")
```

``` r
NIEHS_data_1$W <- rnorm(nrow(NIEHS_data_1), mean = 0, sd = 0.1)
w <- NIEHS_data_1[, c("W", "Z")]
a <- NIEHS_data_1[, c("X1", "X2", "X3", "X4", "X5", "X6", "X7")]
y <- NIEHS_data_1$Y

deltas <- list(
  "X1" = 1, "X2" = 1, "X3" = 1,
  "X4" = 1, "X5" = 1, "X6" = 1, "X7" = 1
)
head(NIEHS_data_1) %>%
  kbl(caption = "NIEHS Data") %>%
  kable_classic(full_width = F, html_font = "Cambria")
```

<table class=" lightable-classic" style="font-family: Cambria; width: auto !important; margin-left: auto; margin-right: auto;">
<caption>
NIEHS Data
</caption>
<thead>
<tr>
<th style="text-align:right;">
obs
</th>
<th style="text-align:right;">
Y
</th>
<th style="text-align:right;">
X1
</th>
<th style="text-align:right;">
X2
</th>
<th style="text-align:right;">
X3
</th>
<th style="text-align:right;">
X4
</th>
<th style="text-align:right;">
X5
</th>
<th style="text-align:right;">
X6
</th>
<th style="text-align:right;">
X7
</th>
<th style="text-align:right;">
Z
</th>
<th style="text-align:right;">
W
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
7.534686
</td>
<td style="text-align:right;">
0.4157066
</td>
<td style="text-align:right;">
0.5308077
</td>
<td style="text-align:right;">
0.2223965
</td>
<td style="text-align:right;">
1.1592634
</td>
<td style="text-align:right;">
2.4577556
</td>
<td style="text-align:right;">
0.9438601
</td>
<td style="text-align:right;">
1.8714406
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
0.1335790
</td>
</tr>
<tr>
<td style="text-align:right;">
2
</td>
<td style="text-align:right;">
19.611934
</td>
<td style="text-align:right;">
0.5293572
</td>
<td style="text-align:right;">
0.9339570
</td>
<td style="text-align:right;">
1.1210595
</td>
<td style="text-align:right;">
1.3350074
</td>
<td style="text-align:right;">
0.3096883
</td>
<td style="text-align:right;">
0.5190970
</td>
<td style="text-align:right;">
0.2418065
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
0.0585291
</td>
</tr>
<tr>
<td style="text-align:right;">
3
</td>
<td style="text-align:right;">
12.664050
</td>
<td style="text-align:right;">
0.4849759
</td>
<td style="text-align:right;">
0.7210988
</td>
<td style="text-align:right;">
0.4629027
</td>
<td style="text-align:right;">
1.0334138
</td>
<td style="text-align:right;">
0.9492810
</td>
<td style="text-align:right;">
0.3664090
</td>
<td style="text-align:right;">
0.3502445
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
0.1342057
</td>
</tr>
<tr>
<td style="text-align:right;">
4
</td>
<td style="text-align:right;">
15.600288
</td>
<td style="text-align:right;">
0.8275456
</td>
<td style="text-align:right;">
1.0457137
</td>
<td style="text-align:right;">
0.9699040
</td>
<td style="text-align:right;">
0.9045099
</td>
<td style="text-align:right;">
0.9107914
</td>
<td style="text-align:right;">
0.4299847
</td>
<td style="text-align:right;">
1.0007901
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
0.0734320
</td>
</tr>
<tr>
<td style="text-align:right;">
5
</td>
<td style="text-align:right;">
18.606498
</td>
<td style="text-align:right;">
0.5190363
</td>
<td style="text-align:right;">
0.7802400
</td>
<td style="text-align:right;">
0.6142188
</td>
<td style="text-align:right;">
0.3729743
</td>
<td style="text-align:right;">
0.5038126
</td>
<td style="text-align:right;">
0.3575472
</td>
<td style="text-align:right;">
0.5906156
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
-0.0148427
</td>
</tr>
<tr>
<td style="text-align:right;">
6
</td>
<td style="text-align:right;">
18.525890
</td>
<td style="text-align:right;">
0.4009491
</td>
<td style="text-align:right;">
0.8639886
</td>
<td style="text-align:right;">
0.5501847
</td>
<td style="text-align:right;">
0.9011016
</td>
<td style="text-align:right;">
1.2907615
</td>
<td style="text-align:right;">
0.7990418
</td>
<td style="text-align:right;">
1.5097039
</td>
<td style="text-align:right;">
0
</td>
<td style="text-align:right;">
0.1749775
</td>
</tr>
</tbody>
</table>

Based on the data key, we expect X1 to have the strongest positive
effect, X5 the strongest negative. So we would expect these to take the
top ranks for these marginal associations. For interactions

``` r

ptm <- proc.time()
sim_results <- InterXshift(
  w = w,
  a = a,
  y = y,
  delta = deltas,
  n_folds = 3,
  num_cores = 6,
  outcome_type = "continuous",
  seed = 294580,
  top_n = 2
)
#> 
#> Iter: 1 fn: 207.8441  Pars:  0.24716 0.75284
#> Iter: 2 fn: 207.8441  Pars:  0.24716 0.75284
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 377.5727  Pars:  0.15499 0.84501
#> Iter: 2 fn: 377.5727  Pars:  0.15499 0.84501
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 330.3357  Pars:  0.0000008108 0.9999991895
#> Iter: 2 fn: 330.3357  Pars:  0.0000003246 0.9999996754
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 401.8556  Pars:  0.86134 0.13866
#> Iter: 2 fn: 401.8556  Pars:  0.86138 0.13862
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 332.3736  Pars:  0.0000004115 0.9999995885
#> Iter: 2 fn: 332.3736  Pars:  0.0000002689 0.9999997311
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 397.6163  Pars:  0.99999899 0.00000101
#> Iter: 2 fn: 397.6163  Pars:  0.9999993431 0.0000006569
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 401.6642  Pars:  0.34162 0.65838
#> Iter: 2 fn: 401.6642  Pars:  0.34162 0.65838
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 394.7229  Pars:  0.999996612 0.000003388
#> Iter: 2 fn: 394.7229  Pars:  0.9999992222 0.0000007778
#> Iter: 3 fn: 394.7229  Pars:  0.9999996471 0.0000003529
#> solnp--> Completed in 3 iterations
#> 
#> Iter: 1 fn: 356.1339  Pars:  0.000005701 0.999994299
#> Iter: 2 fn: 356.1339  Pars:  0.000002949 0.999997051
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 266.7341  Pars:  0.05148 0.94852
#> Iter: 2 fn: 266.7341  Pars:  0.05148 0.94852
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 333.6510  Pars:  0.00000144 0.99999856
#> Iter: 2 fn: 333.6510  Pars:  0.0000008037 0.9999991963
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 400.0847  Pars:  0.999997174 0.000002826
#> Iter: 2 fn: 400.0847  Pars:  0.999998661 0.000001339
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 404.9955  Pars:  0.000001765 0.999998235
#> Iter: 2 fn: 404.9955  Pars:  0.0000005755 0.9999994245
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 398.2493  Pars:  0.91734 0.08266
#> Iter: 2 fn: 398.2493  Pars:  0.91734 0.08266
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 357.3580  Pars:  0.73183 0.26817
#> Iter: 2 fn: 357.3580  Pars:  0.73184 0.26816
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 273.0408  Pars:  0.05909 0.94091
#> Iter: 2 fn: 273.0408  Pars:  0.05909 0.94091
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 183.0370  Pars:  0.01430 0.98570
#> Iter: 2 fn: 183.0370  Pars:  0.01430 0.98570
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 368.3078  Pars:  0.28787 0.71213
#> Iter: 2 fn: 368.3078  Pars:  0.28787 0.71213
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 339.4673  Pars:  0.31384 0.68616
#> Iter: 2 fn: 339.4673  Pars:  0.31385 0.68615
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 383.2973  Pars:  0.09198 0.90802
#> Iter: 2 fn: 383.2973  Pars:  0.09198 0.90802
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 340.5352  Pars:  0.72757 0.27243
#> Iter: 2 fn: 340.5352  Pars:  0.72757 0.27243
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 391.8501  Pars:  0.20653 0.79347
#> Iter: 2 fn: 391.8501  Pars:  0.20653 0.79347
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 393.0514  Pars:  0.41725 0.58275
#> Iter: 2 fn: 393.0514  Pars:  0.41724 0.58276
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 385.7589  Pars:  0.23439 0.76561
#> Iter: 2 fn: 385.7589  Pars:  0.23439 0.76561
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 359.8025  Pars:  0.64588 0.35412
#> Iter: 2 fn: 359.8025  Pars:  0.64589 0.35411
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 298.1049  Pars:  0.13593 0.86407
#> Iter: 2 fn: 298.1049  Pars:  0.13593 0.86407
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 343.2012  Pars:  0.69630 0.30370
#> Iter: 2 fn: 343.2012  Pars:  0.69631 0.30369
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 387.6236  Pars:  0.26685 0.73315
#> Iter: 2 fn: 387.6236  Pars:  0.26685 0.73315
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 382.9423  Pars:  0.38852 0.61148
#> Iter: 2 fn: 382.9423  Pars:  0.38852 0.61148
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 386.7048  Pars:  0.26779 0.73221
#> Iter: 2 fn: 386.7048  Pars:  0.26780 0.73220
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 358.5122  Pars:  0.81840 0.18160
#> Iter: 2 fn: 358.5122  Pars:  0.81843 0.18157
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 299.7883  Pars:  0.18540 0.81460
#> Iter: 2 fn: 299.7883  Pars:  0.18540 0.81460
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 175.6340  Pars:  0.0000000298 0.9999999697
#> Iter: 2 fn: 175.6340  Pars:  0.000000002366 0.999999997634
#> Iter: 3 fn: 175.6340  Pars:  0.000000001002 0.999999998998
#> solnp--> Completed in 3 iterations
#> 
#> Iter: 1 fn: 390.2291  Pars:  0.10353 0.89647
#> Iter: 2 fn: 390.2291  Pars:  0.10353 0.89647
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 345.9065  Pars:  0.0000001012 0.9999998989
#> Iter: 2 fn: 345.9065  Pars:  0.00000006067 0.99999993933
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 400.4320  Pars:  0.04147 0.95853
#> Iter: 2 fn: 400.4320  Pars:  0.04141 0.95859
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 350.7453  Pars:  0.07386 0.92614
#> Iter: 2 fn: 350.7453  Pars:  0.07386 0.92614
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 399.6946  Pars:  0.72024 0.27976
#> Iter: 2 fn: 399.6854  Pars:  0.994207 0.005793
#> Iter: 3 fn: 399.6853  Pars:  0.9997299 0.0002701
#> Iter: 4 fn: 399.6853  Pars:  0.999892 0.000108
#> solnp--> Completed in 4 iterations
#> 
#> Iter: 1 fn: 401.3928  Pars:  0.87583 0.12417
#> Iter: 2 fn: 401.3928  Pars:  0.87590 0.12410
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 402.8578  Pars:  0.000699 0.999301
#> Iter: 2 fn: 398.8164  Pars:  0.999998775 0.000001225
#> Iter: 3 fn: 398.8164  Pars:  0.9999997522 0.0000002478
#> solnp--> Completed in 3 iterations
#> 
#> Iter: 1 fn: 351.1701  Pars:  0.33886 0.66114
#> Iter: 2 fn: 351.1701  Pars:  0.33886 0.66114
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 263.4308  Pars:  0.10274 0.89726
#> Iter: 2 fn: 263.4308  Pars:  0.10275 0.89725
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 349.1731  Pars:  0.09060 0.90940
#> Iter: 2 fn: 349.1731  Pars:  0.09060 0.90940
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 398.4919  Pars:  0.12241 0.87759
#> Iter: 2 fn: 398.4902  Pars:  0.21590 0.78410
#> Iter: 3 fn: 398.4902  Pars:  0.21590 0.78410
#> solnp--> Completed in 3 iterations
#> 
#> Iter: 1 fn: 406.4360  Pars:  0.76833 0.23167
#> Iter: 2 fn: 406.4360  Pars:  0.76833 0.23167
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 403.4659  Pars:  0.90911 0.09089
#> Iter: 2 fn: 403.4659  Pars:  0.90972 0.09028
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 349.7103  Pars:  0.000002336 0.999997663
#> Iter: 2 fn: 349.7103  Pars:  0.0000002178 0.9999997822
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 261.9160  Pars:  0.000002122 0.999997879
#> Iter: 2 fn: 261.9160  Pars:  0.0000004885 0.9999995115
#> solnp--> Completed in 2 iterations
proc.time() - ptm
#>     user   system  elapsed 
#>   76.950    4.150 1362.112

## marginal effects
top_positive_effects <- sim_results$`Pos Shift Results`
top_negative_effects <- sim_results$`Neg Shift Results`

## interaction effects
pooled_synergy_effects <- sim_results$`Pooled Synergy Results`
pooled_antagonism_effects <- sim_results$`Pooled Antagonism Results`

k_fold_synergy_effects <- sim_results$`K Fold Synergy Results`
k_fold_antagonism_effects <- sim_results$`K Fold Antagonism Results`
```

``` r
top_positive_effects %>%
  kbl(caption = "Rank 1 Positive Stochastic Intervention Results") %>%
  kable_classic(full_width = F, html_font = "Cambria")
```

<table class="kable_wrapper lightable-classic" style="font-family: Cambria; width: auto !important; margin-left: auto; margin-right: auto;">
<caption>
Rank 1 Positive Stochastic Intervention Results
</caption>
<tbody>
<tr>
<td>
<table>
<thead>
<tr>
<th style="text-align:left;">
Condition
</th>
<th style="text-align:right;">
Psi
</th>
<th style="text-align:right;">
Variance
</th>
<th style="text-align:right;">
SE
</th>
<th style="text-align:right;">
Lower CI
</th>
<th style="text-align:right;">
Upper CI
</th>
<th style="text-align:right;">
P-value
</th>
<th style="text-align:left;">
Fold
</th>
<th style="text-align:left;">
Type
</th>
<th style="text-align:left;">
Variables
</th>
<th style="text-align:right;">
N
</th>
<th style="text-align:right;">
Delta
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
X1
</td>
<td style="text-align:right;">
13.272347
</td>
<td style="text-align:right;">
0.4610176
</td>
<td style="text-align:right;">
0.6789827
</td>
<td style="text-align:right;">
11.9416
</td>
<td style="text-align:right;">
14.6031
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:left;">
1
</td>
<td style="text-align:left;">
Indiv Shift
</td>
<td style="text-align:left;">
X1
</td>
<td style="text-align:right;">
167
</td>
<td style="text-align:right;">
1
</td>
</tr>
<tr>
<td style="text-align:left;">
X1
</td>
<td style="text-align:right;">
-2.687271
</td>
<td style="text-align:right;">
1.6059094
</td>
<td style="text-align:right;">
1.2672448
</td>
<td style="text-align:right;">
-5.1710
</td>
<td style="text-align:right;">
-0.2035
</td>
<td style="text-align:right;">
0.0339587
</td>
<td style="text-align:left;">
2
</td>
<td style="text-align:left;">
Indiv Shift
</td>
<td style="text-align:left;">
X1
</td>
<td style="text-align:right;">
167
</td>
<td style="text-align:right;">
1
</td>
</tr>
<tr>
<td style="text-align:left;">
X1
</td>
<td style="text-align:right;">
15.980403
</td>
<td style="text-align:right;">
0.6346225
</td>
<td style="text-align:right;">
0.7966320
</td>
<td style="text-align:right;">
14.4190
</td>
<td style="text-align:right;">
17.5418
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:left;">
3
</td>
<td style="text-align:left;">
Indiv Shift
</td>
<td style="text-align:left;">
X1
</td>
<td style="text-align:right;">
166
</td>
<td style="text-align:right;">
1
</td>
</tr>
<tr>
<td style="text-align:left;">
Rank 1
</td>
<td style="text-align:right;">
14.366549
</td>
<td style="text-align:right;">
0.2866767
</td>
<td style="text-align:right;">
0.5354220
</td>
<td style="text-align:right;">
13.3171
</td>
<td style="text-align:right;">
15.4160
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:left;">
Pooled TMLE
</td>
<td style="text-align:left;">
Indiv Shift
</td>
<td style="text-align:left;">
Rank 1
</td>
<td style="text-align:right;">
500
</td>
<td style="text-align:right;">
1
</td>
</tr>
</tbody>
</table>
</td>
<td>
<table>
<thead>
<tr>
<th style="text-align:left;">
Condition
</th>
<th style="text-align:right;">
Psi
</th>
<th style="text-align:right;">
Variance
</th>
<th style="text-align:right;">
SE
</th>
<th style="text-align:right;">
Lower CI
</th>
<th style="text-align:right;">
Upper CI
</th>
<th style="text-align:right;">
P-value
</th>
<th style="text-align:left;">
Fold
</th>
<th style="text-align:left;">
Type
</th>
<th style="text-align:left;">
Variables
</th>
<th style="text-align:right;">
N
</th>
<th style="text-align:right;">
Delta
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
X7
</td>
<td style="text-align:right;">
3.418538
</td>
<td style="text-align:right;">
0.7348417
</td>
<td style="text-align:right;">
0.8572291
</td>
<td style="text-align:right;">
1.7384
</td>
<td style="text-align:right;">
5.0987
</td>
<td style="text-align:right;">
0.0000667
</td>
<td style="text-align:left;">
1
</td>
<td style="text-align:left;">
Indiv Shift
</td>
<td style="text-align:left;">
X7
</td>
<td style="text-align:right;">
167
</td>
<td style="text-align:right;">
1
</td>
</tr>
<tr>
<td style="text-align:left;">
X7
</td>
<td style="text-align:right;">
2.716254
</td>
<td style="text-align:right;">
0.7413940
</td>
<td style="text-align:right;">
0.8610424
</td>
<td style="text-align:right;">
1.0286
</td>
<td style="text-align:right;">
4.4039
</td>
<td style="text-align:right;">
0.0016071
</td>
<td style="text-align:left;">
2
</td>
<td style="text-align:left;">
Indiv Shift
</td>
<td style="text-align:left;">
X7
</td>
<td style="text-align:right;">
167
</td>
<td style="text-align:right;">
1
</td>
</tr>
<tr>
<td style="text-align:left;">
X7
</td>
<td style="text-align:right;">
2.879122
</td>
<td style="text-align:right;">
0.5118995
</td>
<td style="text-align:right;">
0.7154715
</td>
<td style="text-align:right;">
1.4768
</td>
<td style="text-align:right;">
4.2814
</td>
<td style="text-align:right;">
0.0000572
</td>
<td style="text-align:left;">
3
</td>
<td style="text-align:left;">
Indiv Shift
</td>
<td style="text-align:left;">
X7
</td>
<td style="text-align:right;">
166
</td>
<td style="text-align:right;">
1
</td>
</tr>
<tr>
<td style="text-align:left;">
Rank 2
</td>
<td style="text-align:right;">
3.138611
</td>
<td style="text-align:right;">
0.2468434
</td>
<td style="text-align:right;">
0.4968334
</td>
<td style="text-align:right;">
2.1648
</td>
<td style="text-align:right;">
4.1124
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:left;">
Pooled TMLE
</td>
<td style="text-align:left;">
Indiv Shift
</td>
<td style="text-align:left;">
Rank 2
</td>
<td style="text-align:right;">
500
</td>
<td style="text-align:right;">
1
</td>
</tr>
</tbody>
</table>
</td>
</tr>
</tbody>
</table>

Above we show the findings for the top rank positive marginal effect.
Here we consistently find X1 which is true based on what is built into
the DGP.

Next we look at the top negative result:

``` r
top_negative_effects$`Rank 1` %>%
  kbl(caption = "Rank 1 Negative Stochastic Intervention Results") %>%
  kable_classic(full_width = F, html_font = "Cambria")
```

<table class=" lightable-classic" style="font-family: Cambria; width: auto !important; margin-left: auto; margin-right: auto;">
<caption>
Rank 1 Negative Stochastic Intervention Results
</caption>
<thead>
<tr>
<th style="text-align:left;">
Condition
</th>
<th style="text-align:right;">
Psi
</th>
<th style="text-align:right;">
Variance
</th>
<th style="text-align:right;">
SE
</th>
<th style="text-align:right;">
Lower CI
</th>
<th style="text-align:right;">
Upper CI
</th>
<th style="text-align:right;">
P-value
</th>
<th style="text-align:left;">
Fold
</th>
<th style="text-align:left;">
Type
</th>
<th style="text-align:left;">
Variables
</th>
<th style="text-align:right;">
N
</th>
<th style="text-align:right;">
Delta
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
X4
</td>
<td style="text-align:right;">
-0.8445876
</td>
<td style="text-align:right;">
0.7361409
</td>
<td style="text-align:right;">
0.8579865
</td>
<td style="text-align:right;">
-2.5262
</td>
<td style="text-align:right;">
0.8370
</td>
<td style="text-align:right;">
0.3249271
</td>
<td style="text-align:left;">
1
</td>
<td style="text-align:left;">
Indiv Shift
</td>
<td style="text-align:left;">
X4
</td>
<td style="text-align:right;">
167
</td>
<td style="text-align:right;">
1
</td>
</tr>
<tr>
<td style="text-align:left;">
X4
</td>
<td style="text-align:right;">
-0.6088896
</td>
<td style="text-align:right;">
0.7229439
</td>
<td style="text-align:right;">
0.8502611
</td>
<td style="text-align:right;">
-2.2754
</td>
<td style="text-align:right;">
1.0576
</td>
<td style="text-align:right;">
0.4739168
</td>
<td style="text-align:left;">
2
</td>
<td style="text-align:left;">
Indiv Shift
</td>
<td style="text-align:left;">
X4
</td>
<td style="text-align:right;">
167
</td>
<td style="text-align:right;">
1
</td>
</tr>
<tr>
<td style="text-align:left;">
X4
</td>
<td style="text-align:right;">
-0.4510666
</td>
<td style="text-align:right;">
0.5543036
</td>
<td style="text-align:right;">
0.7445157
</td>
<td style="text-align:right;">
-1.9103
</td>
<td style="text-align:right;">
1.0082
</td>
<td style="text-align:right;">
0.5446128
</td>
<td style="text-align:left;">
3
</td>
<td style="text-align:left;">
Indiv Shift
</td>
<td style="text-align:left;">
X4
</td>
<td style="text-align:right;">
166
</td>
<td style="text-align:right;">
1
</td>
</tr>
<tr>
<td style="text-align:left;">
Rank 1
</td>
<td style="text-align:right;">
-0.7797371
</td>
<td style="text-align:right;">
0.2457405
</td>
<td style="text-align:right;">
0.4957222
</td>
<td style="text-align:right;">
-1.7513
</td>
<td style="text-align:right;">
0.1919
</td>
<td style="text-align:right;">
0.1157346
</td>
<td style="text-align:left;">
Pooled TMLE
</td>
<td style="text-align:left;">
Indiv Shift
</td>
<td style="text-align:left;">
Rank 1
</td>
<td style="text-align:right;">
500
</td>
<td style="text-align:right;">
1
</td>
</tr>
</tbody>
</table>

Here we consistently see X5 as having the strongest negative impact
which is also true compared to the true DGP.

Next we will look at the top synergy results which is defined as the
exposures that when shifted jointly have the highest, most positive,
expected outcome difference compared to the sum of individual shifts of
the same variables.

``` r
pooled_synergy_effects$`Rank 1` %>%
  kbl(caption = "Rank 1 Synergy Stochastic Intervention Results") %>%
  kable_classic(full_width = F, html_font = "Cambria")
```

<table class=" lightable-classic" style="font-family: Cambria; width: auto !important; margin-left: auto; margin-right: auto;">
<caption>
Rank 1 Synergy Stochastic Intervention Results
</caption>
<thead>
<tr>
<th style="text-align:left;">
Rank
</th>
<th style="text-align:right;">
Psi
</th>
<th style="text-align:right;">
Variance
</th>
<th style="text-align:right;">
SE
</th>
<th style="text-align:right;">
Lower CI
</th>
<th style="text-align:right;">
Upper CI
</th>
<th style="text-align:right;">
P-value
</th>
<th style="text-align:left;">
Fold
</th>
<th style="text-align:right;">
N
</th>
<th style="text-align:right;">
Delta Exposure 1
</th>
<th style="text-align:right;">
Delta Exposure 2
</th>
<th style="text-align:left;">
Type
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
Rank 1
</td>
<td style="text-align:right;">
-0.7839407
</td>
<td style="text-align:right;">
0.2439296
</td>
<td style="text-align:right;">
0.4938923
</td>
<td style="text-align:right;">
-1.7520
</td>
<td style="text-align:right;">
0.1841
</td>
<td style="text-align:right;">
0.2646390
</td>
<td style="text-align:left;">
Pooled TMLE
</td>
<td style="text-align:right;">
500
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
Var 1
</td>
</tr>
<tr>
<td style="text-align:left;">
Rank 1
</td>
<td style="text-align:right;">
-3.5652153
</td>
<td style="text-align:right;">
0.2374525
</td>
<td style="text-align:right;">
0.4872909
</td>
<td style="text-align:right;">
-4.5203
</td>
<td style="text-align:right;">
-2.6101
</td>
<td style="text-align:right;">
0.0000003
</td>
<td style="text-align:left;">
Pooled TMLE
</td>
<td style="text-align:right;">
500
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
Var 2
</td>
</tr>
<tr>
<td style="text-align:left;">
Rank 1
</td>
<td style="text-align:right;">
-4.0194749
</td>
<td style="text-align:right;">
0.2484014
</td>
<td style="text-align:right;">
0.4983989
</td>
<td style="text-align:right;">
-4.9963
</td>
<td style="text-align:right;">
-3.0426
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:left;">
Pooled TMLE
</td>
<td style="text-align:right;">
500
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
Joint
</td>
</tr>
<tr>
<td style="text-align:left;">
Rank 1
</td>
<td style="text-align:right;">
0.3296811
</td>
<td style="text-align:right;">
0.2511571
</td>
<td style="text-align:right;">
0.5011557
</td>
<td style="text-align:right;">
-0.6526
</td>
<td style="text-align:right;">
1.3119
</td>
<td style="text-align:right;">
0.6414291
</td>
<td style="text-align:left;">
Pooled TMLE
</td>
<td style="text-align:right;">
500
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
Interaction
</td>
</tr>
</tbody>
</table>

Above this table shows the pooled results for the rank 1 synergy
exposure interaction. Of course, the exposure sets in the interaction
deemed to have the highest impact, synergy, may differ between the folds
and thus this pooling may be over different exposure sets. Thus, the
first line shows the pooled estimate for a shift in the first variable,
the second line the second variable, third line the joint and fourth
line the difference between the joint and sum of the first two lines, or
the interaction effect. Therefore, in this case, we could be pooling
over different variables because of inconcistency in what is included as
rank 1 between the folds. Next we look at the k-fold specific results.

``` r
k_fold_synergy_effects$`Rank 1` %>%
  kbl(caption = "K-fold Synergy Stochastic Intervention Results") %>%
  kable_classic(full_width = F, html_font = "Cambria")
```

<table class=" lightable-classic" style="font-family: Cambria; width: auto !important; margin-left: auto; margin-right: auto;">
<caption>
K-fold Synergy Stochastic Intervention Results
</caption>
<thead>
<tr>
<th style="text-align:right;">
Rank
</th>
<th style="text-align:right;">
Psi
</th>
<th style="text-align:right;">
Variance
</th>
<th style="text-align:right;">
SE
</th>
<th style="text-align:right;">
Lower CI
</th>
<th style="text-align:right;">
Upper CI
</th>
<th style="text-align:right;">
P-value
</th>
<th style="text-align:right;">
Fold
</th>
<th style="text-align:right;">
N
</th>
<th style="text-align:right;">
Delta Exposure 1
</th>
<th style="text-align:right;">
Delta Exposure 2
</th>
<th style="text-align:left;">
Type
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
-0.8307433
</td>
<td style="text-align:right;">
0.7422102
</td>
<td style="text-align:right;">
0.8615162
</td>
<td style="text-align:right;">
-2.5193
</td>
<td style="text-align:right;">
0.8578
</td>
<td style="text-align:right;">
0.3707738
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
167
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
X4
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
-3.6842524
</td>
<td style="text-align:right;">
0.6854063
</td>
<td style="text-align:right;">
0.8278927
</td>
<td style="text-align:right;">
-5.3069
</td>
<td style="text-align:right;">
-2.0616
</td>
<td style="text-align:right;">
0.0000514
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
167
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
X5
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
-3.8745306
</td>
<td style="text-align:right;">
0.6396612
</td>
<td style="text-align:right;">
0.7997882
</td>
<td style="text-align:right;">
-5.4421
</td>
<td style="text-align:right;">
-2.3070
</td>
<td style="text-align:right;">
0.0000147
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
167
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
X4-X5
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
0.6404651
</td>
<td style="text-align:right;">
0.8229767
</td>
<td style="text-align:right;">
0.9071806
</td>
<td style="text-align:right;">
-1.1376
</td>
<td style="text-align:right;">
2.4185
</td>
<td style="text-align:right;">
0.5013085
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
167
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
Interaction
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
-0.6414818
</td>
<td style="text-align:right;">
0.7115233
</td>
<td style="text-align:right;">
0.8435184
</td>
<td style="text-align:right;">
-2.2947
</td>
<td style="text-align:right;">
1.0118
</td>
<td style="text-align:right;">
0.4848941
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:right;">
167
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
X4
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
-3.8106050
</td>
<td style="text-align:right;">
0.7023745
</td>
<td style="text-align:right;">
0.8380779
</td>
<td style="text-align:right;">
-5.4532
</td>
<td style="text-align:right;">
-2.1680
</td>
<td style="text-align:right;">
0.0000315
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:right;">
167
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
X5
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
-3.9552472
</td>
<td style="text-align:right;">
1.0958593
</td>
<td style="text-align:right;">
1.0468330
</td>
<td style="text-align:right;">
-6.0070
</td>
<td style="text-align:right;">
-1.9035
</td>
<td style="text-align:right;">
0.0001107
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:right;">
167
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
X4-X5
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
0.4968396
</td>
<td style="text-align:right;">
1.0111131
</td>
<td style="text-align:right;">
1.0055412
</td>
<td style="text-align:right;">
-1.4740
</td>
<td style="text-align:right;">
2.4677
</td>
<td style="text-align:right;">
0.6202693
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:right;">
167
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
Interaction
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
-0.5022413
</td>
<td style="text-align:right;">
0.5467407
</td>
<td style="text-align:right;">
0.7394192
</td>
<td style="text-align:right;">
-1.9515
</td>
<td style="text-align:right;">
0.9470
</td>
<td style="text-align:right;">
0.5591713
</td>
<td style="text-align:right;">
3
</td>
<td style="text-align:right;">
166
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
X4
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
-3.3334914
</td>
<td style="text-align:right;">
0.4549681
</td>
<td style="text-align:right;">
0.6745133
</td>
<td style="text-align:right;">
-4.6555
</td>
<td style="text-align:right;">
-2.0115
</td>
<td style="text-align:right;">
0.0000493
</td>
<td style="text-align:right;">
3
</td>
<td style="text-align:right;">
166
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
X5
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
-3.8353454
</td>
<td style="text-align:right;">
0.4708589
</td>
<td style="text-align:right;">
0.6861916
</td>
<td style="text-align:right;">
-5.1803
</td>
<td style="text-align:right;">
-2.4904
</td>
<td style="text-align:right;">
0.0000037
</td>
<td style="text-align:right;">
3
</td>
<td style="text-align:right;">
166
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
X4-X5
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
0.0003873
</td>
<td style="text-align:right;">
0.5123543
</td>
<td style="text-align:right;">
0.7157893
</td>
<td style="text-align:right;">
-1.4025
</td>
<td style="text-align:right;">
1.4033
</td>
<td style="text-align:right;">
0.9996347
</td>
<td style="text-align:right;">
3
</td>
<td style="text-align:right;">
166
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
Interaction
</td>
</tr>
</tbody>
</table>

Here we see that the interaction between X4 and X5 was consistently
found to have the highest antagonistic interaction across the folds.
Therefore, for our pooled parameter var 1 represents the pooled effects
of shifting X4, var 2 represents the pooled effects of shifting X5,
joint is X4 and X5 together and the interaction represents the
interaction effect for these two variables.

Next we’ll look at the k-fold antagonistic interactions:

``` r
k_fold_antagonism_effects$`Rank 1` %>%
  kbl(caption = "K-fold Antagonistic Stochastic Intervention Results") %>%
  kable_classic(full_width = F, html_font = "Cambria")
```

<table class=" lightable-classic" style="font-family: Cambria; width: auto !important; margin-left: auto; margin-right: auto;">
<caption>
K-fold Antagonistic Stochastic Intervention Results
</caption>
<thead>
<tr>
<th style="text-align:right;">
Rank
</th>
<th style="text-align:right;">
Psi
</th>
<th style="text-align:right;">
Variance
</th>
<th style="text-align:right;">
SE
</th>
<th style="text-align:right;">
Lower CI
</th>
<th style="text-align:right;">
Upper CI
</th>
<th style="text-align:right;">
P-value
</th>
<th style="text-align:right;">
Fold
</th>
<th style="text-align:right;">
N
</th>
<th style="text-align:right;">
Delta Exposure 1
</th>
<th style="text-align:right;">
Delta Exposure 2
</th>
<th style="text-align:left;">
Type
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
-0.8417448
</td>
<td style="text-align:right;">
0.7276929
</td>
<td style="text-align:right;">
0.8530492
</td>
<td style="text-align:right;">
-2.5137
</td>
<td style="text-align:right;">
0.8302
</td>
<td style="text-align:right;">
0.3621019
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
167
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
X4
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
-3.7508836
</td>
<td style="text-align:right;">
0.6817120
</td>
<td style="text-align:right;">
0.8256585
</td>
<td style="text-align:right;">
-5.3691
</td>
<td style="text-align:right;">
-2.1326
</td>
<td style="text-align:right;">
0.0000366
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
167
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
X5
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
-3.8262154
</td>
<td style="text-align:right;">
0.6713063
</td>
<td style="text-align:right;">
0.8193329
</td>
<td style="text-align:right;">
-5.4321
</td>
<td style="text-align:right;">
-2.2204
</td>
<td style="text-align:right;">
0.0000237
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
167
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
X4-X5
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
0.7664130
</td>
<td style="text-align:right;">
0.8668148
</td>
<td style="text-align:right;">
0.9310289
</td>
<td style="text-align:right;">
-1.0584
</td>
<td style="text-align:right;">
2.5912
</td>
<td style="text-align:right;">
0.4270243
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
167
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
Interaction
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
-0.6171086
</td>
<td style="text-align:right;">
0.7073394
</td>
<td style="text-align:right;">
0.8410347
</td>
<td style="text-align:right;">
-2.2655
</td>
<td style="text-align:right;">
1.0313
</td>
<td style="text-align:right;">
0.5010069
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:right;">
167
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
X4
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
-3.7414210
</td>
<td style="text-align:right;">
0.7056593
</td>
<td style="text-align:right;">
0.8400353
</td>
<td style="text-align:right;">
-5.3879
</td>
<td style="text-align:right;">
-2.0950
</td>
<td style="text-align:right;">
0.0000446
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:right;">
167
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
X5
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
-4.0338956
</td>
<td style="text-align:right;">
1.1183969
</td>
<td style="text-align:right;">
1.0575429
</td>
<td style="text-align:right;">
-6.1066
</td>
<td style="text-align:right;">
-1.9611
</td>
<td style="text-align:right;">
0.0000876
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:right;">
167
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
X4-X5
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
0.3246339
</td>
<td style="text-align:right;">
0.9701553
</td>
<td style="text-align:right;">
0.9849646
</td>
<td style="text-align:right;">
-1.6059
</td>
<td style="text-align:right;">
2.2551
</td>
<td style="text-align:right;">
0.7435905
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:right;">
167
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
Interaction
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
-0.4952579
</td>
<td style="text-align:right;">
0.5544481
</td>
<td style="text-align:right;">
0.7446127
</td>
<td style="text-align:right;">
-1.9547
</td>
<td style="text-align:right;">
0.9642
</td>
<td style="text-align:right;">
0.5660087
</td>
<td style="text-align:right;">
3
</td>
<td style="text-align:right;">
166
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
X4
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
-3.3504760
</td>
<td style="text-align:right;">
0.4553080
</td>
<td style="text-align:right;">
0.6747651
</td>
<td style="text-align:right;">
-4.6730
</td>
<td style="text-align:right;">
-2.0280
</td>
<td style="text-align:right;">
0.0000453
</td>
<td style="text-align:right;">
3
</td>
<td style="text-align:right;">
166
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
X5
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
-3.9422309
</td>
<td style="text-align:right;">
0.4672794
</td>
<td style="text-align:right;">
0.6835783
</td>
<td style="text-align:right;">
-5.2820
</td>
<td style="text-align:right;">
-2.6024
</td>
<td style="text-align:right;">
0.0000019
</td>
<td style="text-align:right;">
3
</td>
<td style="text-align:right;">
166
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
X4-X5
</td>
</tr>
<tr>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
-0.0964970
</td>
<td style="text-align:right;">
0.5204951
</td>
<td style="text-align:right;">
0.7214535
</td>
<td style="text-align:right;">
-1.5105
</td>
<td style="text-align:right;">
1.3175
</td>
<td style="text-align:right;">
0.9095484
</td>
<td style="text-align:right;">
3
</td>
<td style="text-align:right;">
166
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
Interaction
</td>
</tr>
</tbody>
</table>

Overall, this package provides implementation of estimation a
non-parametric definition of interaction. We define positive values as
synergy meaning the expected outcome under joint shift is much larger
compared to individual addivitive effects. Likewise, we define
antagonism as negative effects, the joint value being lower than the
additive effects.

------------------------------------------------------------------------

## Issues

If you encounter any bugs or have any specific feature requests, please
[file an issue](https://github.com/blind-contours/InterXshift/issues).
Further details on filing issues are provided in our [contribution
guidelines](https://github.com/blind-contours/%20InterXshift/main/contributing.md).

------------------------------------------------------------------------

## Contributions

Contributions are very welcome. Interested contributors should consult
our [contribution
guidelines](https://github.com/blind-contours/InterXshift/blob/master/CONTRIBUTING.md)
prior to submitting a pull request.

------------------------------------------------------------------------

## Citation

After using the `InterXshift` R package, please cite the following:

------------------------------------------------------------------------

## Related

- [R/`tmle3shift`](https://github.com/tlverse/tmle3shift) - An R package
  providing an independent implementation of the same core routines for
  the TML estimation procedure and statistical methodology as is made
  available here, through reliance on a unified interface for Targeted
  Learning provided by the [`tmle3`](https://github.com/tlverse/tmle3)
  engine of the [`tlverse` ecosystem](https://github.com/tlverse).

- [R/`medshift`](https://github.com/nhejazi/medshift) - An R package
  providing facilities to estimate the causal effect of stochastic
  treatment regimes in the mediation setting, including classical (IPW)
  and augmented double robust (one-step) estimators. This is an
  implementation of the methodology explored by Dı́az and Hejazi (2020).

- [R/`haldensify`](https://github.com/nhejazi/haldensify) - A minimal
  package for estimating the conditional density treatment mechanism
  component of this parameter based on using the [highly adaptive
  lasso](https://github.com/tlverse/hal9001) (Coyle, Hejazi, Phillips,
  et al. 2022; Hejazi, Coyle, and van der Laan 2020) in combination with
  a pooled hazard regression. This package implements a variant of the
  approach advocated by Dı́az and van der Laan (2011).

------------------------------------------------------------------------

## Funding

The development of this software was supported in part through grants
from the

------------------------------------------------------------------------

## License

© 2020-2022 [David B. McCoy](https://davidmccoy.org)

The contents of this repository are distributed under the MIT license.
See below for details:

    MIT License
    Copyright (c) 2020-2022 David B. McCoy
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

------------------------------------------------------------------------

## References

<div id="refs" class="references csl-bib-body hanging-indent">

<div id="ref-coyle-sl3-rpkg" class="csl-entry">

Coyle, Jeremy R, Nima S Hejazi, Ivana Malenica, Rachael V Phillips, and
Oleg Sofrygin. 2022. “<span class="nocase">sl3</span>: Modern Machine
Learning Pipelines for Super Learning.”
<https://doi.org/10.5281/zenodo.1342293>.

</div>

<div id="ref-coyle-hal9001-rpkg" class="csl-entry">

Coyle, Jeremy R, Nima S Hejazi, Rachael V Phillips, Lars W van der Laan,
and Mark J van der Laan. 2022. “<span class="nocase">hal9001</span>: The
Scalable Highly Adaptive Lasso.”
<https://doi.org/10.5281/zenodo.3558313>.

</div>

<div id="ref-diaz2020causal" class="csl-entry">

Dı́az, Iván, and Nima S Hejazi. 2020. “Causal Mediation Analysis for
Stochastic Interventions.” *Journal of the Royal Statistical Society:
Series B (Statistical Methodology)* 82 (3): 661–83.
<https://doi.org/10.1111/rssb.12362>.

</div>

<div id="ref-diaz2011super" class="csl-entry">

Dı́az, Iván, and Mark J van der Laan. 2011. “Super Learner Based
Conditional Density Estimation with Application to Marginal Structural
Models.” *The International Journal of Biostatistics* 7 (1): 1–20.

</div>

<div id="ref-diaz2012population" class="csl-entry">

———. 2012. “Population Intervention Causal Effects Based on Stochastic
Interventions.” *Biometrics* 68 (2): 541–49.

</div>

<div id="ref-haneuse2013estimation" class="csl-entry">

Haneuse, Sebastian, and Andrea Rotnitzky. 2013. “Estimation of the
Effect of Interventions That Modify the Received Treatment.” *Statistics
in Medicine* 32 (30): 5260–77.

</div>

<div id="ref-hejazi2020hal9001-joss" class="csl-entry">

Hejazi, Nima S, Jeremy R Coyle, and Mark J van der Laan. 2020.
“<span class="nocase">hal9001</span>: Scalable Highly Adaptive Lasso
Regression in R.” *Journal of Open Source Software* 5 (53): 2526.
<https://doi.org/10.21105/joss.02526>.

</div>

<div id="ref-mccoy2023semiparametric" class="csl-entry">

McCoy, David B., Alan E. Hubbard, Alejandro Schuler, and Mark J. van der
Laan. 2023. “Semi-Parametric Identification and Estimation of
Interaction and Effect Modification in Mixed Exposures Using Stochastic
Interventions.” <https://arxiv.org/abs/2305.01849>.

</div>

</div>
