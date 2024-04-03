
<!-- README.md is generated from README.Rmd. Please edit that file -->

# R/`IsoXshift`

<!-- badges: start -->

[![R-CMD-check](https://github.com/blind-contours/IsoXshift/workflows/R-CMD-check/badge.svg)](https://github.com/blind-contours/IsoXshift/actions)
[![Coverage
Status](https://img.shields.io/codecov/c/github/blind-contours/IsoXshift/master.svg)](https://codecov.io/github/blind-contours/IsoXshift?branch=master)
[![CRAN](https://www.r-pkg.org/badges/version/IsoXshift)](https://www.r-pkg.org/pkg/IsoXshift)
[![CRAN
downloads](https://cranlogs.r-pkg.org/badges/IsoXshift)](https://CRAN.R-project.org/package=IsoXshift)
[![CRAN total
downloads](http://cranlogs.r-pkg.org/badges/grand-total/IsoXshift)](https://CRAN.R-project.org/package=IsoXshift)
[![Project Status: Active – The project has reached a stable, usable
state and is being actively
developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![MIT
license](https://img.shields.io/badge/license-MIT-brightgreen.svg)](https://opensource.org/licenses/MIT)
<!-- [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.4070042.svg)](https://doi.org/10.5281/zenodo.4070042) -->
<!-- [![DOI](https://joss.theoj.org/papers/10.21105/joss.02447/status.svg)](https://doi.org/10.21105/joss.02447) -->
<!-- badges: end -->

> Isobolic Interaction Identification and Estimation using Data-Adaptive
> Stochastic Interventions **Authors:** [David
> McCoy](https://davidmccoy.org)

------------------------------------------------------------------------

## What’s `IsoXshift`?

<img src="https://github.com/blind-contours/IsoXshift/blob/main/IsoXshift_sticker.png" width="230">

The `IsoXshift` R package offers an approach which identifies the
minimum effort intervention on two exposures which, if the population
were given these intervention levels, would result in a target outcome.
This parameter reflects the most synergistic interaction or set of
interactions in a mixed exposure. The target parameter is similar to
isobolic interactions used in toxicology studies where researchers
investigate how much simultaneous dose of two exposures results in a
target outcome, like cancer or cell death in cultures.

From a policy perspective, this parameter represents the most efficient
intervention that can be done on a mixed exposure to get to a desired
outcome. This is because, for a collection of possible interventions or
changes to pollutants, for example, we find the exposure set that most
efficiently results in an expected outcome close to our desired outcome.
Efficient here means the exposure(s) need to be shifted the least to get
to a desired outcome, like pre-industry levels of thyroid cancer etc.

## Realistic Interventions

This package first identifies the most efficient intervention policy
that gets to a desired outcome using g-computation which results in two
exposure levels a set of exposures should be set to. Because it’s
unrealistic to set a population to this specific oracle intervention,
because the likelihood of certain individuals exposed to this level may
be near 0, we instead estimate the effects of the policy if we were to
get everyone as close as possible to this oracle level. This is done by
finding an intervention level as close to the oracle level as possible
under some restrictions that the individual conditional likelihood of
being exposed doesn’t move too far away from their observed levels.

We the estimate the impact of our “intention to intervene” using
CV-TMLE. Using this oracle point paramater as our target we shift
individuals as close as possible to this level without violating the
density ratio, the intervention level exposure likelihood compared to
observed level likelihood. Thus, each individuals actual intervention is
different but is aimed towards the target, hence intention to intervene.

## Joint vs. Additive Interventions

We define interaction as the counterfactual mean of the outcome under
stochastic interventions of two exposures compared to the additive
counterfactual mean of the two exposures intervened on independently.
These interventions or exposure changes depend on naturally observed
values, as described in past literature (Dı́az and van der Laan 2012;
Haneuse and Rotnitzky 2013), but with our new parameter in mind. Thus,
what is estimated is like asking, what the expected outcome is if we
were to enforce the most efficient policy intervention in a realistic
setting where not everyone can actually receive that exact exposure
level or levels.

## Target Levels and Shifting to those Levels

To utilize the package, users need to provide vectors for exposures,
covariates, and outcomes. They also specify the target_outcome_lvl for
the outcome, epsilon, which is some allowed closeness to the target. For
example, if the target outcome level is 15, and epsilon is 0.5, then
interventions that lead to 15.5 are considered. The restriction limit is
hn_trunc_thresh which is the allowed distance from the original exposure
likelihood. 10 for example indicates that the likelihood should not be
more than x10 difference from the original exposure level likelihood.
That is, if an individual’s likelihood is originally 0.1 given their
covariate history and the likelihood of exposure to the intervened level
is 0.01, this is 10 times different and would be the limit intervention.

A detailed guide is provided in the vignette. With these inputs,
`IsoXshift` processes the data and delivers tables showcasing
fold-specific results and aggregated outcomes, allowing users to glean
insights effectively.

`IsoXshift` also incorporates features from the `sl3` package (Coyle,
Hejazi, Malenica, et al. 2022), facilitating ensemble machine learning
in the estimation process. If the user does not specify any stack
parameters, `IsoXshift` will automatically create an ensemble of machine
learning algorithms that strike a balance between flexibility and
computational efficiency.

------------------------------------------------------------------------

## Installation

*Note:* Because the `IsoXshift` package (currently) depends on `sl3`
that allows ensemble machine learning to be used for nuisance parameter
estimation and `sl3` is not on CRAN the `IsoXshift` package is not
available on CRAN and must be downloaded here.

`IsoXshift` uses the `sl3` package to build ensemble machine learners
for each nuisance parameter. We have to install off the development
branch, first download these two packages for `sl3`

``` r
remotes::install_github("tlverse/sl3@devel")
```

Make sure `sl3` installs correctly then install `IsoXshift`

``` r
remotes::install_github("blind-contours/IsoXshift@main")
```

------------------------------------------------------------------------

## Example

To illustrate how `IsoXshift` may be used to ascertain the effect of a
mixed exposure, we will use synthetic data from the National Institute
of Environmental Health. Let’s first load the relevant packages:

``` r
library(IsoXshift)
library(devtools)
#> Loading required package: usethis
library(kableExtra)
library(sl3)

seed <- 429153
set.seed(seed)
```

We will directly use synthetic data from the NIEHS used to test new
mixture methods. This data has built in strong positive and negative
marginal effects and certain interactions. Found here:
<https://github.com/niehs-prime/2015-NIEHS-MIxtures-Workshop>

``` r
data("NIEHS_data_1", package = "IsoXshift")
```

``` r
NIEHS_data_1$W <- rnorm(nrow(NIEHS_data_1), mean = 0, sd = 0.1)
w <- NIEHS_data_1[, c("W", "Z")]
a <- NIEHS_data_1[, c("X1", "X2", "X3", "X4", "X5", "X6", "X7")]
y <- NIEHS_data_1$Y

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

Let’s look at the interactions built into this synthetic data:

<img src="https://github.com/blind-contours/IsoXshift/blob/main/man/figures/NIEHS_interactions.png" width="230">

This shows that X1 and X7 has the most synergy or super-additive effect
so we might expect to find this relationship as the most synergistic
exposure relationship based on our definition. It is also possible that
the most efficient intervention is one that intervents on an
antagonistic pair, shifting positive associations higher and negative
lower in the antagonistic interaction.

``` r

ptm <- proc.time()
sim_results <- IsoXshift(
  w = w,
  a = a,
  y = y,
  n_folds = 6,
  num_cores = 6,
  outcome_type = "continuous",
  seed = seed,
  target_outcome_lvl = 12,
  epsilon = 0.5
)
#> 
#> Iter: 1 fn: 222.8222  Pars:  0.02601 0.97399
#> Iter: 2 fn: 222.8222  Pars:  0.02601 0.97399
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 494.9785  Pars:  0.000007745 0.999992255
#> Iter: 2 fn: 494.9785  Pars:  0.00000003548 0.99999996452
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 487.6227  Pars:  0.999994298 0.000005701
#> Iter: 2 fn: 487.6227  Pars:  0.9999991589 0.0000008411
#> Iter: 3 fn: 487.6227  Pars:  0.9999994859 0.0000005141
#> solnp--> Completed in 3 iterations
#> 
#> Iter: 1 fn: 226.2807  Pars:  0.05745 0.94255
#> Iter: 2 fn: 226.2807  Pars:  0.05745 0.94255
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 484.0375  Pars:  0.0000005784 0.9999994218
#> Iter: 2 fn: 484.0375  Pars:  0.0000001083 0.9999998917
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 479.8223  Pars:  0.37822 0.62178
#> Iter: 2 fn: 479.8223  Pars:  0.37820 0.62180
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 221.0642  Pars:  0.00000005466 0.99999994546
#> Iter: 2 fn: 221.0642  Pars:  0.00000003637 0.99999996363
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 496.3027  Pars:  0.21429 0.78571
#> Iter: 2 fn: 496.3027  Pars:  0.21398 0.78602
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 491.9260  Pars:  0.0000125 0.9999875
#> Iter: 2 fn: 491.9260  Pars:  0.000007487 0.999992513
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 104.6614  Pars:  0.08134 0.91866
#> Iter: 2 fn: 104.6614  Pars:  0.08134 0.91866
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 495.9732  Pars:  0.41785 0.58215
#> Iter: 2 fn: 495.9732  Pars:  0.41785 0.58215
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 495.9761  Pars:  0.9999993936 0.0000006071
#> Iter: 2 fn: 495.9761  Pars:  0.9999996437 0.0000003563
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 220.9891  Pars:  0.00000000428 0.99999999571
#> Iter: 2 fn: 220.9891  Pars:  0.00000000105 0.99999999895
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 496.7959  Pars:  0.32776 0.67224
#> Iter: 2 fn: 496.7959  Pars:  0.32777 0.67223
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 498.7841  Pars:  0.99999888 0.00000112
#> Iter: 2 fn: 498.7841  Pars:  0.9999997064 0.0000002936
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 235.0054  Pars:  0.03661 0.96339
#> Iter: 2 fn: 235.0054  Pars:  0.03661 0.96339
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 492.8295  Pars:  0.999995555 0.000004445
#> Iter: 2 fn: 492.8295  Pars:  0.999998947 0.000001053
#> Iter: 3 fn: 492.8295  Pars:  0.9999995304 0.0000004696
#> solnp--> Completed in 3 iterations
#> 
#> Iter: 1 fn: 491.7396  Pars:  0.9999963 0.0000037
#> Iter: 2 fn: 491.7396  Pars:  0.999997994 0.000002006
#> solnp--> Completed in 2 iterations
proc.time() - ptm
#>    user  system elapsed 
#>  66.048   5.430 948.089

oracle_parameter <- sim_results$`Oracle Pooled Results`
k_fold_results <- sim_results$`K-fold Results`
oracle_targets <- sim_results$`K Fold Oracle Targets`
```

Of note: these results will be more consistent with higher folds but
here we use 6 so readme builds more quickly for users.

## K-fold Specific Results

``` r
k_fold_results <- do.call(rbind, k_fold_results)
rownames(k_fold_results) <- NULL

k_fold_results %>%
  kbl(caption = "List of K Fold Results") %>%
  kable_classic(full_width = F, html_font = "Cambria")
```

<table class=" lightable-classic" style="font-family: Cambria; width: auto !important; margin-left: auto; margin-right: auto;">
<caption>
List of K Fold Results
</caption>
<thead>
<tr>
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
N
</th>
<th style="text-align:left;">
Type
</th>
<th style="text-align:right;">
Fold
</th>
<th style="text-align:left;">
Average Delta
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
-13.5086705
</td>
<td style="text-align:right;">
0.0273477
</td>
<td style="text-align:right;">
0.1653715
</td>
<td style="text-align:right;">
-13.8328
</td>
<td style="text-align:right;">
-13.1845
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:right;">
84
</td>
<td style="text-align:left;">
X1
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
-0.902
</td>
</tr>
<tr>
<td style="text-align:right;">
-12.1225847
</td>
<td style="text-align:right;">
0.2853685
</td>
<td style="text-align:right;">
0.5341989
</td>
<td style="text-align:right;">
-13.1696
</td>
<td style="text-align:right;">
-11.0756
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:right;">
84
</td>
<td style="text-align:left;">
X5
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
2.222
</td>
</tr>
<tr>
<td style="text-align:right;">
-14.7686203
</td>
<td style="text-align:right;">
0.0086283
</td>
<td style="text-align:right;">
0.0928884
</td>
<td style="text-align:right;">
-14.9507
</td>
<td style="text-align:right;">
-14.5866
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:right;">
84
</td>
<td style="text-align:left;">
X1-X5
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
-0.902-2.222
</td>
</tr>
<tr>
<td style="text-align:right;">
10.8626348
</td>
<td style="text-align:right;">
0.1947857
</td>
<td style="text-align:right;">
0.4413453
</td>
<td style="text-align:right;">
9.9976
</td>
<td style="text-align:right;">
11.7277
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:right;">
84
</td>
<td style="text-align:left;">
Interaction
</td>
<td style="text-align:right;">
1
</td>
<td style="text-align:left;">
-0.902-2.222
</td>
</tr>
<tr>
<td style="text-align:right;">
0.7719493
</td>
<td style="text-align:right;">
0.9860012
</td>
<td style="text-align:right;">
0.9929759
</td>
<td style="text-align:right;">
-1.1742
</td>
<td style="text-align:right;">
2.7181
</td>
<td style="text-align:right;">
0.4385318
</td>
<td style="text-align:right;">
84
</td>
<td style="text-align:left;">
X1
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:left;">
-0.871
</td>
</tr>
<tr>
<td style="text-align:right;">
0.9442252
</td>
<td style="text-align:right;">
0.6999801
</td>
<td style="text-align:right;">
0.8366482
</td>
<td style="text-align:right;">
-0.6956
</td>
<td style="text-align:right;">
2.5840
</td>
<td style="text-align:right;">
0.3019336
</td>
<td style="text-align:right;">
84
</td>
<td style="text-align:left;">
X5
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:left;">
2.023
</td>
</tr>
<tr>
<td style="text-align:right;">
10.2589986
</td>
<td style="text-align:right;">
1.5165367
</td>
<td style="text-align:right;">
1.2314774
</td>
<td style="text-align:right;">
7.8453
</td>
<td style="text-align:right;">
12.6726
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:right;">
84
</td>
<td style="text-align:left;">
X1-X5
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:left;">
-0.871-2.023
</td>
</tr>
<tr>
<td style="text-align:right;">
8.5428240
</td>
<td style="text-align:right;">
1.0429063
</td>
<td style="text-align:right;">
1.0212279
</td>
<td style="text-align:right;">
6.5413
</td>
<td style="text-align:right;">
10.5444
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:right;">
84
</td>
<td style="text-align:left;">
Interaction
</td>
<td style="text-align:right;">
2
</td>
<td style="text-align:left;">
-0.871-2.023
</td>
</tr>
<tr>
<td style="text-align:right;">
-0.6416571
</td>
<td style="text-align:right;">
0.6609212
</td>
<td style="text-align:right;">
0.8129706
</td>
<td style="text-align:right;">
-2.2351
</td>
<td style="text-align:right;">
0.9517
</td>
<td style="text-align:right;">
0.4766824
</td>
<td style="text-align:right;">
83
</td>
<td style="text-align:left;">
X1
</td>
<td style="text-align:right;">
3
</td>
<td style="text-align:left;">
-0.893
</td>
</tr>
<tr>
<td style="text-align:right;">
-2.2660756
</td>
<td style="text-align:right;">
0.6944661
</td>
<td style="text-align:right;">
0.8333463
</td>
<td style="text-align:right;">
-3.8994
</td>
<td style="text-align:right;">
-0.6327
</td>
<td style="text-align:right;">
0.0130522
</td>
<td style="text-align:right;">
83
</td>
<td style="text-align:left;">
X5
</td>
<td style="text-align:right;">
3
</td>
<td style="text-align:left;">
1.942
</td>
</tr>
<tr>
<td style="text-align:right;">
2.7737158
</td>
<td style="text-align:right;">
1.7005188
</td>
<td style="text-align:right;">
1.3040394
</td>
<td style="text-align:right;">
0.2178
</td>
<td style="text-align:right;">
5.3296
</td>
<td style="text-align:right;">
0.0151431
</td>
<td style="text-align:right;">
83
</td>
<td style="text-align:left;">
X1-X5
</td>
<td style="text-align:right;">
3
</td>
<td style="text-align:left;">
-0.893-1.942
</td>
</tr>
<tr>
<td style="text-align:right;">
5.6814485
</td>
<td style="text-align:right;">
0.4304117
</td>
<td style="text-align:right;">
0.6560577
</td>
<td style="text-align:right;">
4.3956
</td>
<td style="text-align:right;">
6.9673
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:right;">
83
</td>
<td style="text-align:left;">
Interaction
</td>
<td style="text-align:right;">
3
</td>
<td style="text-align:left;">
-0.893-1.942
</td>
</tr>
<tr>
<td style="text-align:right;">
-0.9763588
</td>
<td style="text-align:right;">
1.0797738
</td>
<td style="text-align:right;">
1.0391217
</td>
<td style="text-align:right;">
-3.0130
</td>
<td style="text-align:right;">
1.0603
</td>
<td style="text-align:right;">
0.3381620
</td>
<td style="text-align:right;">
83
</td>
<td style="text-align:left;">
X1
</td>
<td style="text-align:right;">
4
</td>
<td style="text-align:left;">
-0.899
</td>
</tr>
<tr>
<td style="text-align:right;">
8.4683426
</td>
<td style="text-align:right;">
1.0442643
</td>
<td style="text-align:right;">
1.0218925
</td>
<td style="text-align:right;">
6.4655
</td>
<td style="text-align:right;">
10.4712
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:right;">
83
</td>
<td style="text-align:left;">
X5
</td>
<td style="text-align:right;">
4
</td>
<td style="text-align:left;">
1.941
</td>
</tr>
<tr>
<td style="text-align:right;">
5.4460469
</td>
<td style="text-align:right;">
1.9400116
</td>
<td style="text-align:right;">
1.3928430
</td>
<td style="text-align:right;">
2.7161
</td>
<td style="text-align:right;">
8.1760
</td>
<td style="text-align:right;">
0.0000039
</td>
<td style="text-align:right;">
83
</td>
<td style="text-align:left;">
X1-X5
</td>
<td style="text-align:right;">
4
</td>
<td style="text-align:left;">
-0.899-1.941
</td>
</tr>
<tr>
<td style="text-align:right;">
-2.0459369
</td>
<td style="text-align:right;">
0.7792955
</td>
<td style="text-align:right;">
0.8827772
</td>
<td style="text-align:right;">
-3.7761
</td>
<td style="text-align:right;">
-0.3157
</td>
<td style="text-align:right;">
0.0294401
</td>
<td style="text-align:right;">
83
</td>
<td style="text-align:left;">
Interaction
</td>
<td style="text-align:right;">
4
</td>
<td style="text-align:left;">
-0.899-1.941
</td>
</tr>
<tr>
<td style="text-align:right;">
-9.3113201
</td>
<td style="text-align:right;">
0.1582846
</td>
<td style="text-align:right;">
0.3978500
</td>
<td style="text-align:right;">
-10.0911
</td>
<td style="text-align:right;">
-8.5315
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:right;">
83
</td>
<td style="text-align:left;">
X1
</td>
<td style="text-align:right;">
5
</td>
<td style="text-align:left;">
-0.939
</td>
</tr>
<tr>
<td style="text-align:right;">
-6.3934531
</td>
<td style="text-align:right;">
1.0026758
</td>
<td style="text-align:right;">
1.0013370
</td>
<td style="text-align:right;">
-8.3560
</td>
<td style="text-align:right;">
-4.4309
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:right;">
83
</td>
<td style="text-align:left;">
X5
</td>
<td style="text-align:right;">
5
</td>
<td style="text-align:left;">
1.589
</td>
</tr>
<tr>
<td style="text-align:right;">
-16.1190466
</td>
<td style="text-align:right;">
0.1048507
</td>
<td style="text-align:right;">
0.3238066
</td>
<td style="text-align:right;">
-16.7537
</td>
<td style="text-align:right;">
-15.4844
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:right;">
83
</td>
<td style="text-align:left;">
X1-X5
</td>
<td style="text-align:right;">
5
</td>
<td style="text-align:left;">
-0.939-1.589
</td>
</tr>
<tr>
<td style="text-align:right;">
-0.4142735
</td>
<td style="text-align:right;">
1.3869984
</td>
<td style="text-align:right;">
1.1777090
</td>
<td style="text-align:right;">
-2.7225
</td>
<td style="text-align:right;">
1.8940
</td>
<td style="text-align:right;">
0.7026539
</td>
<td style="text-align:right;">
83
</td>
<td style="text-align:left;">
Interaction
</td>
<td style="text-align:right;">
5
</td>
<td style="text-align:left;">
-0.939-1.589
</td>
</tr>
<tr>
<td style="text-align:right;">
-6.2074296
</td>
<td style="text-align:right;">
0.1879825
</td>
<td style="text-align:right;">
0.4335695
</td>
<td style="text-align:right;">
-7.0572
</td>
<td style="text-align:right;">
-5.3576
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:right;">
83
</td>
<td style="text-align:left;">
X1
</td>
<td style="text-align:right;">
6
</td>
<td style="text-align:left;">
-0.858
</td>
</tr>
<tr>
<td style="text-align:right;">
-5.4070107
</td>
<td style="text-align:right;">
0.5718131
</td>
<td style="text-align:right;">
0.7561833
</td>
<td style="text-align:right;">
-6.8891
</td>
<td style="text-align:right;">
-3.9249
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:right;">
83
</td>
<td style="text-align:left;">
X5
</td>
<td style="text-align:right;">
6
</td>
<td style="text-align:left;">
1.687
</td>
</tr>
<tr>
<td style="text-align:right;">
-13.2608365
</td>
<td style="text-align:right;">
0.1036790
</td>
<td style="text-align:right;">
0.3219922
</td>
<td style="text-align:right;">
-13.8919
</td>
<td style="text-align:right;">
-12.6297
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:right;">
83
</td>
<td style="text-align:left;">
X1-X5
</td>
<td style="text-align:right;">
6
</td>
<td style="text-align:left;">
-0.858-1.687
</td>
</tr>
<tr>
<td style="text-align:right;">
-1.6463962
</td>
<td style="text-align:right;">
1.2525969
</td>
<td style="text-align:right;">
1.1191948
</td>
<td style="text-align:right;">
-3.8400
</td>
<td style="text-align:right;">
0.5472
</td>
<td style="text-align:right;">
0.1196468
</td>
<td style="text-align:right;">
83
</td>
<td style="text-align:left;">
Interaction
</td>
<td style="text-align:right;">
6
</td>
<td style="text-align:left;">
-0.858-1.687
</td>
</tr>
</tbody>
</table>

Here we see that X1-X5 are found in all the folds. This means that, to
get to our target outcome of 15, with precision up to 0.5, these two
exposures are found to most efficiently get to our target outcome under
minimal intervention.

The column Psi shows the expected change in outcome under shift compared
to no shift. Type indicates which variable was shifted, X1, X5, X1 and
X5 and then interaction which compares X1-X5 to X1 + X5. So for example
a Psi of -13.5 for X1 indicates that the outcome reduces by 13.5 when we
attempt to shift X1 towards the oracle point paramter. Which in this
fold is 0.05. So under a policy where we try and shift X1 towards the
value 0.05 under restrictions of not violating positivity support the
outcome goes down by 13.5.

The average delta column indicates the average shift away from each
individuals observed exposure level in order to reach the target under
restrictions.

## Oracle Point Parameters

These interventions are:

``` r
oracle_targets <- do.call(rbind, oracle_targets)
oracle_targets %>%
  kbl(caption = "Oracle Targets") %>%
  kable_classic(full_width = F, html_font = "Cambria")
```

<table class=" lightable-classic" style="font-family: Cambria; width: auto !important; margin-left: auto; margin-right: auto;">
<caption>
Oracle Targets
</caption>
<thead>
<tr>
<th style="text-align:left;">
</th>
<th style="text-align:left;">
Variable1
</th>
<th style="text-align:left;">
Variable2
</th>
<th style="text-align:right;">
ObservedLevel1
</th>
<th style="text-align:right;">
ObservedLevel2
</th>
<th style="text-align:right;">
IntervenedLevel1
</th>
<th style="text-align:right;">
IntervenedLevel2
</th>
<th style="text-align:right;">
AvgDiff
</th>
<th style="text-align:right;">
Difference
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:left;">
1
</td>
<td style="text-align:left;">
X1
</td>
<td style="text-align:left;">
X5
</td>
<td style="text-align:right;">
1.155827
</td>
<td style="text-align:right;">
1.242123
</td>
<td style="text-align:right;">
0.0566475
</td>
<td style="text-align:right;">
3.414815
</td>
<td style="text-align:right;">
1.635936
</td>
<td style="text-align:right;">
0.0668849
</td>
</tr>
<tr>
<td style="text-align:left;">
2
</td>
<td style="text-align:left;">
X1
</td>
<td style="text-align:left;">
X5
</td>
<td style="text-align:right;">
1.147629
</td>
<td style="text-align:right;">
1.218358
</td>
<td style="text-align:right;">
0.0481946
</td>
<td style="text-align:right;">
3.414815
</td>
<td style="text-align:right;">
1.647946
</td>
<td style="text-align:right;">
0.3846076
</td>
</tr>
<tr>
<td style="text-align:left;">
3
</td>
<td style="text-align:left;">
X1
</td>
<td style="text-align:left;">
X5
</td>
<td style="text-align:right;">
1.143893
</td>
<td style="text-align:right;">
1.235131
</td>
<td style="text-align:right;">
0.0481946
</td>
<td style="text-align:right;">
3.155947
</td>
<td style="text-align:right;">
1.508257
</td>
<td style="text-align:right;">
0.0206467
</td>
</tr>
<tr>
<td style="text-align:left;">
21
</td>
<td style="text-align:left;">
X1
</td>
<td style="text-align:left;">
X5
</td>
<td style="text-align:right;">
1.124229
</td>
<td style="text-align:right;">
1.236977
</td>
<td style="text-align:right;">
0.2923519
</td>
<td style="text-align:right;">
3.155947
</td>
<td style="text-align:right;">
1.375423
</td>
<td style="text-align:right;">
0.2560524
</td>
</tr>
<tr>
<td style="text-align:left;">
11
</td>
<td style="text-align:left;">
X1
</td>
<td style="text-align:left;">
X5
</td>
<td style="text-align:right;">
1.140465
</td>
<td style="text-align:right;">
1.249656
</td>
<td style="text-align:right;">
0.0481946
</td>
<td style="text-align:right;">
2.751177
</td>
<td style="text-align:right;">
1.296896
</td>
<td style="text-align:right;">
0.4992674
</td>
</tr>
<tr>
<td style="text-align:left;">
12
</td>
<td style="text-align:left;">
X1
</td>
<td style="text-align:left;">
X5
</td>
<td style="text-align:right;">
1.140439
</td>
<td style="text-align:right;">
1.240693
</td>
<td style="text-align:right;">
0.0481946
</td>
<td style="text-align:right;">
2.897264
</td>
<td style="text-align:right;">
1.374408
</td>
<td style="text-align:right;">
0.1197868
</td>
</tr>
</tbody>
</table>

Here this table shows the average exposed level for each exposure, the
intervened level for both exposures, this is the level the exposures are
set to which gets to the target outcome most efficiently, Avg
Difference, is the average difference between the intervention and
observed outcome (the “effort”), and Difference is the difference
between the expected outcome under intervention and the target outcome.

What we see here is that to get to the target outcome 12, where the
observed average is 53, so a significant reduction, the most efficient
intervention is to reduce X1 to around 0.05 and to increase X5 (due to
its antagonistic relationship) to about 3.

To get more power, we do a pooled TMLE over our findings for the
intervention with minimal effort that gets to our target outcome:

## Oracle Parameter

``` r
oracle_parameter %>%
  kbl(caption = "Pooled Oracle Parameter") %>%
  kable_classic(full_width = F, html_font = "Cambria")
```

<table class=" lightable-classic" style="font-family: Cambria; width: auto !important; margin-left: auto; margin-right: auto;">
<caption>
Pooled Oracle Parameter
</caption>
<thead>
<tr>
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
N
</th>
<th style="text-align:left;">
Type
</th>
<th style="text-align:left;">
Fold
</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
-4.500727
</td>
<td style="text-align:right;">
0.0942057
</td>
<td style="text-align:right;">
0.3069295
</td>
<td style="text-align:right;">
-5.1023
</td>
<td style="text-align:right;">
-3.8992
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:right;">
500
</td>
<td style="text-align:left;">
Var 1
</td>
<td style="text-align:left;">
Pooled TMLE
</td>
</tr>
<tr>
<td style="text-align:right;">
-5.274783
</td>
<td style="text-align:right;">
0.1789838
</td>
<td style="text-align:right;">
0.4230647
</td>
<td style="text-align:right;">
-6.1040
</td>
<td style="text-align:right;">
-4.4456
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:right;">
500
</td>
<td style="text-align:left;">
Var 2
</td>
<td style="text-align:left;">
Pooled TMLE
</td>
</tr>
<tr>
<td style="text-align:right;">
-8.023789
</td>
<td style="text-align:right;">
0.0973612
</td>
<td style="text-align:right;">
0.3120275
</td>
<td style="text-align:right;">
-8.6354
</td>
<td style="text-align:right;">
-7.4122
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:right;">
500
</td>
<td style="text-align:left;">
Joint
</td>
<td style="text-align:left;">
Pooled TMLE
</td>
</tr>
<tr>
<td style="text-align:right;">
1.751721
</td>
<td style="text-align:right;">
0.1782565
</td>
<td style="text-align:right;">
0.4222043
</td>
<td style="text-align:right;">
0.9242
</td>
<td style="text-align:right;">
2.5792
</td>
<td style="text-align:right;">
0.0070199
</td>
<td style="text-align:right;">
500
</td>
<td style="text-align:left;">
Interaction
</td>
<td style="text-align:left;">
Pooled TMLE
</td>
</tr>
</tbody>
</table>

This gives pooled estimates for the shift of each variable in the
relationship individually, joint and our definition of interaction
comparing the expectation of the outcome under joint shift compared to
the expectations under the sum of individual shifts.

Overall, this package finds the intervention that, with minimal effort,
gets to a desired outcome in a mixed exposure. It then estimates, using
CV-TMLE, a policy intervention that attempts to get a population’s
exposure as close as possible to this oracle intervention level without
violating positivity.

In this NIEHS data set we correctly identify the most synergistic
relationship built into the data.

More discussion is found in the vignette.

------------------------------------------------------------------------

## Issues

If you encounter any bugs or have any specific feature requests, please
[file an issue](https://github.com/blind-contours/IsoXshift/issues).
Further details on filing issues are provided in our [contribution
guidelines](https://github.com/blind-contours/%20IsoXshift/main/contributing.md).

------------------------------------------------------------------------

## Contributions

Contributions are very welcome. Interested contributors should consult
our [contribution
guidelines](https://github.com/blind-contours/IsoXshift/blob/master/CONTRIBUTING.md)
prior to submitting a pull request.

------------------------------------------------------------------------

## Citation

After using the `IsoXshift` R package, please cite the following:

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

The development of this software was supported in part through NIH grant
P42ES004705 from NIEHS

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

</div>
