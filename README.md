
<!-- README.md is generated from README.Rmd. Please edit that file -->

# R/`SuperNOVA` <img src="man/figures/SuperNOVA_sticker.png" height="300" align="right"/>

<!-- badges: start -->

[![R-CMD-check](https://github.com/blind-contours/SuperNOVA/workflows/R-CMD-check/badge.svg)](https://github.com/blind-contours/SuperNOVA/actions)
[![Coverage
Status](https://img.shields.io/codecov/c/github/blind-contours/SuperNOVA/master.svg)](https://codecov.io/github/blind-contours/SuperNOVA?branch=master)
[![CRAN](https://www.r-pkg.org/badges/version/SupernOVA)](https://www.r-pkg.org/pkg/SuperNOVA)
[![CRAN
downloads](https://cranlogs.r-pkg.org/badges/SuperNOVA)](https://CRAN.R-project.org/package=SuperNOVA)
[![CRAN total
downloads](http://cranlogs.r-pkg.org/badges/grand-total/SuperNOVA)](https://CRAN.R-project.org/package=SuperNOVA)
[![Project Status: Active – The project has reached a stable, usable
state and is being actively
developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![MIT
license](https://img.shields.io/badge/license-MIT-brightgreen.svg)](https://opensource.org/licenses/MIT)
<!-- [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.4070042.svg)](https://doi.org/10.5281/zenodo.4070042) -->
<!-- [![DOI](https://joss.theoj.org/papers/10.21105/joss.02447/status.svg)](https://doi.org/10.21105/joss.02447) -->
<!-- badges: end -->

> Efficient Estimation of the Causal Effects of Non-Parametric
> Interactions and Effect Modifications using Stochastic Interventions
> **Authors:** [David McCoy](https://davidmccoy.org)

------------------------------------------------------------------------

## What’s `SuperNOVA`?

The `SuperNOVA` R package provides users with the tools necessary to
identify the most predictive variable sets for a given outcome and
develop efficient estimators for the counterfactual mean of the outcome
under stochastic interventions on those variables. These interventions
are shifts to the exposures that are dependent on naturally observed
values (Dı́az and van der Laan 2012; Haneuse and Rotnitzky 2013).
Building on the `txshift` package, which implements the TML estimator
for a stochastic shift causal parameter, `SuperNOVA` extends this
methodology to include joint stochastic interventions on two variables,
allowing for the construction of a non-parametric interaction parameter
and mediation (in development). Additionally, `SuperNOVA` estimates
individual stochastic intervention outcomes under some delta shift
compared to the outcome under no intervention, and a target parameter
for effect modification, which is the mean outcome under intervention in
regions of the covariate space that are also data-adaptively determined.

The `SuperNOVA` package provides a comprehensive solution for
identifying variable sets that interact or modify effects in the context
of mixed exposures. To achieve this, we use a k-fold cross-validation
framework to estimate a data-adaptive parameter, namely, stochastic
shift target parameters for variable sets that are discovered to be
predictive of the outcome. We ensure unbiased estimation of the
data-adaptive parameter by employing cross-validated targeted maximum
likelihood estimation. In this approach, we split the data into
parameter-generating and estimation samples. In the parameter-generating
sample, we fit an ensemble of basis function estimators to the data and
select the estimator with the lowest cross-validated mean squared error.
We then extract important variable sets using ANOVA-like variance
decomposition of the linear combination of basis functions. In the
estimation fold, we use targeted learning to estimate causal target
parameters for interaction, effect modification, and individual variable
shifts. That is, we estimate the counterfactual mean different of these
discovered variable sets under a shift of $\delta$ (an amount to shift
an exposure by) compared to the observed outcome under observed
exposure. `SuperNOVA` is a versatile tool that provides researchers with
k-fold specific and pooled results for each target parameter. More
details are available in the accompanying vignette.

Users simply input a vector for exposures, covariates, and an outcome.
The user also specifies the respective $\delta$ for each exposure (the
amount to shift by) and if this delta should be adaptive based on
positivity violations (see vignette). `SuperNOVA` comes with flexible
default machine learning algorithms used in the data-adaptive procedure
and for estimation of each of the nuisance parameters. Given these
inputs `SuperNOVA` outputs tables for fold specific results (say
exposure 1 under shifts for each fold it was found predictive) and
pooled results which uses a pooled TMLE fluctuation across the folds to
esimate an average effect.

`SuperNOVA` integrates with the [`sl3`
package](https://github.com/tlverse/sl3) (Coyle, Hejazi, Malenica, et
al. 2022) to allow for ensemble machine learning to be leveraged in the
estimation procedure for each nuisance parameter and estimation of the
data-adaptive parameters. There are several stacks of machine learning
algorithms used that are constructed from `sl3` automatically. If the
stack parameters are NULL, SuperNOVA automatically builds ensembles of
machine learning algorithms that are flexible yet not overly
computationally taxing.

------------------------------------------------------------------------

## Installation

*Note:* Because the `SuperNOVA` package (currently) depends on `sl3`
that allows ensemble machine learning to be used for nuisance parameter
estimation and `sl3` is not on CRAN the `SuperNOVA` package is not
available on CRAN and must be downloaded here.

There are many depedencies for `SuperNOVA` so it’s easier to break up
installation of the various packages to ensure proper installation.

First install the basis estimators used in the data-adaptive variable
discovery of the exposure and covariate space:

``` r
install.packages("earth")
install.packages("hal9001")
```

`SuperNOVA` uses the `sl3` package to build ensemble machine learners
for each nuisance parameter. We have to install off the development
branch, first download these two packages for `sl3`

``` r
install.packages(c("ranger", "arm", "xgboost", "nnls"))
```

Now install `sl3` on devel:

``` r
remotes::install_github("tlverse/sl3@devel")
```

Make sure `sl3` installs correctly then install `SuperNOVA`

``` r
remotes::install_github("blind-contours/SuperNOVA@main")
```

`SuperNOVA` has some other miscellaneous dependencies that are used in
the examples as well as in the plotting functions.

``` r
install.packages(c("kableExtra", "hrbrthemes", "viridis"))
```

------------------------------------------------------------------------

## Example

To illustrate how `SuperNOVA` may be used to ascertain the effect of a
mixed exposure, consider the following example:

``` r
library(SuperNOVA)
library(devtools)
#> Loading required package: usethis
library(kableExtra)
library(sl3)

set.seed(429153)
# simulate simple data
n_obs <- 100000
```

The `simulate_data` function creates simulated data with a multivariate
exposure, covariates (confounders), and a continuous outcome.

``` r
data <- simulate_data(n_obs = n_obs, shift_var_index = c(3))
effect <- data$effect
data <- data$data
head(data) %>%
  kbl(caption = "Simulated Data") %>%
  kable_classic(full_width = F, html_font = "Cambria")
```

<table class=" lightable-classic" style="font-family: Cambria; width: auto !important; margin-left: auto; margin-right: auto;">
<caption>
Simulated Data
</caption>
<thead>
<tr>
<th style="text-align:right;">
M1
</th>
<th style="text-align:right;">
M2
</th>
<th style="text-align:right;">
M3
</th>
<th style="text-align:right;">
W1
</th>
<th style="text-align:right;">
W2
</th>
<th style="text-align:right;">
Y
</th>
<th style="text-align:right;">
Y_shifted
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
5.122589
</td>
<td style="text-align:right;">
0.6810488
</td>
<td style="text-align:right;">
3.098372
</td>
<td style="text-align:right;">
7.873068
</td>
<td style="text-align:right;">
7.362137
</td>
<td style="text-align:right;">
8.727373
</td>
<td style="text-align:right;">
8.796372
</td>
</tr>
<tr>
<td style="text-align:right;">
5.752568
</td>
<td style="text-align:right;">
3.9186685
</td>
<td style="text-align:right;">
4.723786
</td>
<td style="text-align:right;">
6.677126
</td>
<td style="text-align:right;">
7.302253
</td>
<td style="text-align:right;">
8.549657
</td>
<td style="text-align:right;">
8.552309
</td>
</tr>
<tr>
<td style="text-align:right;">
4.515052
</td>
<td style="text-align:right;">
0.9926542
</td>
<td style="text-align:right;">
2.979040
</td>
<td style="text-align:right;">
7.598614
</td>
<td style="text-align:right;">
7.647076
</td>
<td style="text-align:right;">
8.290229
</td>
<td style="text-align:right;">
8.369829
</td>
</tr>
<tr>
<td style="text-align:right;">
3.816552
</td>
<td style="text-align:right;">
-0.1666900
</td>
<td style="text-align:right;">
1.502374
</td>
<td style="text-align:right;">
7.321127
</td>
<td style="text-align:right;">
6.907626
</td>
<td style="text-align:right;">
6.539904
</td>
<td style="text-align:right;">
7.549933
</td>
</tr>
<tr>
<td style="text-align:right;">
4.797729
</td>
<td style="text-align:right;">
1.8740593
</td>
<td style="text-align:right;">
4.024303
</td>
<td style="text-align:right;">
6.203951
</td>
<td style="text-align:right;">
6.547683
</td>
<td style="text-align:right;">
7.192016
</td>
<td style="text-align:right;">
7.200583
</td>
</tr>
<tr>
<td style="text-align:right;">
4.380270
</td>
<td style="text-align:right;">
0.2098730
</td>
<td style="text-align:right;">
2.961153
</td>
<td style="text-align:right;">
7.677073
</td>
<td style="text-align:right;">
8.250861
</td>
<td style="text-align:right;">
8.473848
</td>
<td style="text-align:right;">
8.556300
</td>
</tr>
</tbody>
</table>

The `shift_var_index` parameter above shifts a variable set and gets the
expected outcome under this shift. Here, we shift our first exposure
variable and true effect for this DGP is:

``` r
effect
#> [1] 0.2057182
```

And therefore, in `SuperNOVA` we would expect most of the fold CIs to
cover this number and the pooled estimate to also cover this true
effect. Let’s run `SuperNOVA` to see if it correctly identifies the
exposures that drive the outcome and any interaction/effect modification
that exists in the DGP.

Of note, there are three exposures M1, M2, M3 - M1 and M3 have
individual effects and interactions that drive the outcome. There is
also effect modification between M3 and W1.

``` r
data_sample <- data[sample(nrow(data), 1000), ]

w <- data_sample[, c("W1", "W2")]
a <- data_sample[, c("M1", "M2", "M3")]
y <- data_sample$Y

deltas <- list("M1" = 1, "M2" = 1, "M3" = 1)

ptm <- proc.time()
sim_results <- SuperNOVA(
  w = w,
  a = a,
  y = y,
  delta = deltas,
  n_folds = 2,
  num_cores = 6,
  family = "continuous",
  quantile_thresh = 0,
  seed = 294580
)
#> 
#> Iter: 1 fn: 736.1309  Pars:  0.999990593 0.000009407
#> Iter: 2 fn: 736.1309  Pars:  0.99999736 0.00000264
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 731.4051  Pars:  0.9995572 0.0004428
#> Iter: 2 fn: 731.4051  Pars:  0.99992727 0.00007273
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 736.7229  Pars:  0.99996647 0.00003353
#> Iter: 2 fn: 736.7229  Pars:  0.999992347 0.000007653
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 732.0024  Pars:  0.97476 0.02524
#> Iter: 2 fn: 731.7276  Pars:  0.68600 0.31400
#> Iter: 3 fn: 731.7276  Pars:  0.68600 0.31400
#> solnp--> Completed in 3 iterations
#> 
#> Iter: 1 fn: 733.1242  Pars:  0.9994124 0.0005876
#> Iter: 2 fn: 733.1242  Pars:  0.9998624 0.0001376
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 738.3274  Pars:  0.99997363 0.00002637
#> Iter: 2 fn: 738.3274  Pars:  0.99998491 0.00001509
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 734.5190  Pars:  0.99999247 0.00000753
#> Iter: 2 fn: 734.5190  Pars:  0.999995305 0.000004695
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 737.4888  Pars:  0.99998296 0.00001704
#> Iter: 2 fn: 737.4888  Pars:  0.999996248 0.000003752
#> solnp--> Completed in 2 iterations
proc.time() - ptm
#>     user   system  elapsed 
#>   60.293    4.658 1066.582

indiv_shift_results <- sim_results$`Indiv Shift Results`
em_results <- sim_results$`Effect Mod Results`
joint_shift_results <- sim_results$`Joint Shift Results`
```

Let’s first look at the results for individual stochastic shifts by
delta compared to no shift:

``` r
indiv_shift_results$M3 %>%
  kbl(caption = "Individual Stochastic Intervention Results for M1") %>%
  kable_classic(full_width = F, html_font = "Cambria")
```

<table class=" lightable-classic" style="font-family: Cambria; width: auto !important; margin-left: auto; margin-right: auto;">
<caption>
Individual Stochastic Intervention Results for M1
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
M3
</td>
<td style="text-align:right;">
0.4781234
</td>
<td style="text-align:right;">
0.0187581
</td>
<td style="text-align:right;">
0.1369602
</td>
<td style="text-align:right;">
0.2097
</td>
<td style="text-align:right;">
0.7466
</td>
<td style="text-align:right;">
0.0004813
</td>
<td style="text-align:left;">
1
</td>
<td style="text-align:left;">
Indiv Shift
</td>
<td style="text-align:left;">
M3
</td>
<td style="text-align:right;">
500
</td>
<td style="text-align:right;">
1
</td>
</tr>
<tr>
<td style="text-align:left;">
M3
</td>
<td style="text-align:right;">
0.2560727
</td>
<td style="text-align:right;">
0.1685680
</td>
<td style="text-align:right;">
0.4105704
</td>
<td style="text-align:right;">
-0.5486
</td>
<td style="text-align:right;">
1.0608
</td>
<td style="text-align:right;">
0.5328247
</td>
<td style="text-align:left;">
2
</td>
<td style="text-align:left;">
Indiv Shift
</td>
<td style="text-align:left;">
M3
</td>
<td style="text-align:right;">
500
</td>
<td style="text-align:right;">
1
</td>
</tr>
<tr>
<td style="text-align:left;">
M3
</td>
<td style="text-align:right;">
0.3098747
</td>
<td style="text-align:right;">
0.0347372
</td>
<td style="text-align:right;">
0.1863791
</td>
<td style="text-align:right;">
-0.0554
</td>
<td style="text-align:right;">
0.6752
</td>
<td style="text-align:right;">
0.0963916
</td>
<td style="text-align:left;">
Pooled TMLE
</td>
<td style="text-align:left;">
Indiv Shift
</td>
<td style="text-align:left;">
M3
</td>
<td style="text-align:right;">
1000
</td>
<td style="text-align:right;">
1
</td>
</tr>
</tbody>
</table>

Next we can look at effect modifications:

``` r
em_results$M3W1 %>%
  kbl(caption = "Effect Modification Stochastic Intervention Results for M3 and W1") %>%
  kable_classic(full_width = F, html_font = "Cambria")
```

<table class=" lightable-classic" style="font-family: Cambria; width: auto !important; margin-left: auto; margin-right: auto;">
<caption>
Effect Modification Stochastic Intervention Results for M3 and W1
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
Level 1 Shift Diff in W1 \<= 4.79548872632324
</td>
<td style="text-align:right;">
6.608877
</td>
<td style="text-align:right;">
9.8017436
</td>
<td style="text-align:right;">
3.1307736
</td>
<td style="text-align:right;">
0.4727
</td>
<td style="text-align:right;">
12.7451
</td>
<td style="text-align:right;">
0.0347774
</td>
<td style="text-align:left;">
1
</td>
<td style="text-align:left;">
Effect Mod
</td>
<td style="text-align:left;">
M3W1
</td>
<td style="text-align:right;">
500
</td>
<td style="text-align:right;">
1
</td>
</tr>
<tr>
<td style="text-align:left;">
Level 0 Shift Diff in W1 \<= 4.79548872632324
</td>
<td style="text-align:right;">
7.497494
</td>
<td style="text-align:right;">
0.0369747
</td>
<td style="text-align:right;">
0.1922882
</td>
<td style="text-align:right;">
7.1206
</td>
<td style="text-align:right;">
7.8744
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:left;">
1
</td>
<td style="text-align:left;">
Effect Mod
</td>
<td style="text-align:left;">
M3W1
</td>
<td style="text-align:right;">
500
</td>
<td style="text-align:right;">
1
</td>
</tr>
<tr>
<td style="text-align:left;">
Level 1 Shift Diff in W1 \<= 6.01707155372336
</td>
<td style="text-align:right;">
6.522368
</td>
<td style="text-align:right;">
0.5981337
</td>
<td style="text-align:right;">
0.7733910
</td>
<td style="text-align:right;">
5.0065
</td>
<td style="text-align:right;">
8.0382
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:left;">
2
</td>
<td style="text-align:left;">
Effect Mod
</td>
<td style="text-align:left;">
M3W1
</td>
<td style="text-align:right;">
500
</td>
<td style="text-align:right;">
1
</td>
</tr>
<tr>
<td style="text-align:left;">
Level 0 Shift Diff in W1 \<= 6.01707155372336
</td>
<td style="text-align:right;">
8.303153
</td>
<td style="text-align:right;">
2.5621008
</td>
<td style="text-align:right;">
1.6006564
</td>
<td style="text-align:right;">
5.1659
</td>
<td style="text-align:right;">
11.4404
</td>
<td style="text-align:right;">
0.0000002
</td>
<td style="text-align:left;">
2
</td>
<td style="text-align:left;">
Effect Mod
</td>
<td style="text-align:left;">
M3W1
</td>
<td style="text-align:right;">
500
</td>
<td style="text-align:right;">
1
</td>
</tr>
<tr>
<td style="text-align:left;">
Level 1 Shift Diff in W1 \<= 6.02939925010252
</td>
<td style="text-align:right;">
6.695511
</td>
<td style="text-align:right;">
0.3626356
</td>
<td style="text-align:right;">
0.6021923
</td>
<td style="text-align:right;">
5.5152
</td>
<td style="text-align:right;">
7.8758
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:left;">
Pooled TMLE
</td>
<td style="text-align:left;">
Effect Mod
</td>
<td style="text-align:left;">
M3W1
</td>
<td style="text-align:right;">
1000
</td>
<td style="text-align:right;">
1
</td>
</tr>
<tr>
<td style="text-align:left;">
Level 0 Shift Diff in W1 \<= 6.02939925010252
</td>
<td style="text-align:right;">
8.399997
</td>
<td style="text-align:right;">
0.4258269
</td>
<td style="text-align:right;">
0.6525541
</td>
<td style="text-align:right;">
7.1210
</td>
<td style="text-align:right;">
9.6790
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:left;">
Pooled TMLE
</td>
<td style="text-align:left;">
Effect Mod
</td>
<td style="text-align:left;">
M3W1
</td>
<td style="text-align:right;">
1000
</td>
<td style="text-align:right;">
1
</td>
</tr>
</tbody>
</table>

And finally results for the joint shift which is a joint shift compared
to additive individual shifts.

``` r
joint_shift_results$M1M3 %>%
  kbl(caption = "Interactions Stochastic Intervention Results") %>%
  kable_classic(full_width = F, html_font = "Cambria")
```

<table class=" lightable-classic" style="font-family: Cambria; width: auto !important; margin-left: auto; margin-right: auto;">
<caption>
Interactions Stochastic Intervention Results
</caption>
<tbody>
<tr>
</tr>
</tbody>
</table>

------------------------------------------------------------------------

## Issues

If you encounter any bugs or have any specific feature requests, please
[file an issue](https://github.com/blind-contours/SuperNOVA/issues).
Further details on filing issues are provided in our [contribution
guidelines](https://github.com/blind-contours/%20SuperNOVA/main/contributing.md).

------------------------------------------------------------------------

## Contributions

Contributions are very welcome. Interested contributors should consult
our [contribution
guidelines](https://github.com/blind-contours/SuperNOVA/blob/master/CONTRIBUTING.md)
prior to submitting a pull request.

------------------------------------------------------------------------

## Citation

After using the `SuperNOVA` R package, please cite the following:

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
Oleg Sofrygin. 2022. *<span class="nocase">sl3</span>: Modern Machine
Learning Pipelines for Super Learning*.
<https://doi.org/10.5281/zenodo.1342293>.

</div>

<div id="ref-coyle-hal9001-rpkg" class="csl-entry">

Coyle, Jeremy R, Nima S Hejazi, Rachael V Phillips, Lars W van der Laan,
and Mark J van der Laan. 2022. *<span class="nocase">hal9001</span>: The
Scalable Highly Adaptive Lasso*.
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

Hejazi, Nima S, Jeremy R Coyle, and Mark J van der Laan. 2020. “<span
class="nocase">hal9001</span>: Scalable Highly Adaptive Lasso Regression
in R.” *Journal of Open Source Software* 5 (53): 2526.
<https://doi.org/10.21105/joss.02526>.

</div>

</div>
