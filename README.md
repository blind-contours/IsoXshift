
<!-- README.md is generated from README.Rmd. Please edit that file -->

# R/`IsoXshift` <img src="man/figures/IsoXshift_sticker.png" align="right" height="200" style="float:right; height:200px;"/>

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

We define interaction as the counterfactual mean of the outcome under
stochastic interventions of two exposures compared to the additive
counterfactual mean of the two exposures intervened on independently.
These interventions or exposure changes depend on naturally observed
values, as described in past literature (Dı́az and van der Laan 2012;
Haneuse and Rotnitzky 2013), but with our new parameter in mind. Thus,
what is estimated is like asking, what the expected outcome is if we
were to enforce the most efficient policy intervention in a realistic
setting where not everyone can actually recieve that exact exposure
level or levels.

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
parameters, `InterXshift` will automatically create an ensemble of
machine learning algorithms that strike a balance between flexibility
and computational efficiency.

------------------------------------------------------------------------

## Installation

*Note:* Because the `IsoXshift` package (currently) depends on `sl3`
that allows ensemble machine learning to be used for nuisance parameter
estimation and `sl3` is not on CRAN the `IsoXshift` package is not
available on CRAN and must be downloaded here.

There are many depedencies for `IsoXshift` so it’s easier to break up
installation of the various packages to ensure proper installation.

First install the basis estimators used in the data-adaptive variable
discovery of the exposure and covariate space:

``` r
install.packages("earth")
install.packages("hal9001")
```

`IsoXshift` uses the `sl3` package to build ensemble machine learners
for each nuisance parameter. We have to install off the development
branch, first download these two packages for `sl3`

``` r
install.packages(c("ranger", "arm", "xgboost", "nnls"))
```

Now install `sl3` on devel:

``` r
remotes::install_github("tlverse/sl3@devel")
```

Make sure `sl3` installs correctly then install `IsoXshift`

``` r
remotes::install_github("blind-contours/IsoXshift@main")
```

`IsoXshift` has some other miscellaneous dependencies that are used in
the examples as well as in the plotting functions.

``` r
install.packages(c("kableExtra", "hrbrthemes", "viridis"))
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

<figure>
<img src="%22man/figures/NIEHS_interactions.png%22"
alt="NIEHS Interactions" />
<figcaption aria-hidden="true">NIEHS Interactions</figcaption>
</figure>

This shows that X1 and X7 has the most synergy or super-additive effect
so we might expect to find this relationship as the most synergistic
exposure relationship based on our definition.

``` r

ptm <- proc.time()
sim_results <- IsoXshift(
  w = w,
  a = a,
  y = y,
  n_folds = 5,
  num_cores = 6,
  outcome_type = "continuous",
  seed = seed,
  target_outcome_lvl = 15,
  epsilon = 0.5
)
#> 
#> Iter: 1 fn: 191.9358  Pars:  0.0000003908 0.9999996094
#> Iter: 2 fn: 191.9358  Pars:  0.0000001602 0.9999998398
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 448.1996  Pars:  0.03804 0.96196
#> Iter: 2 fn: 448.1996  Pars:  0.03804 0.96196
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 461.3076  Pars:  0.22580 0.77420
#> Iter: 2 fn: 461.3076  Pars:  0.22580 0.77420
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 180.8586  Pars:  0.02992 0.97008
#> Iter: 2 fn: 180.8586  Pars:  0.02991 0.97009
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 466.2345  Pars:  0.003087 0.996913
#> Iter: 2 fn: 466.2345  Pars:  0.002355 0.997645
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 464.6877  Pars:  0.999994892 0.000005108
#> Iter: 2 fn: 464.6877  Pars:  0.999998399 0.000001601
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 199.3252  Pars:  0.00000004247 0.99999995594
#> Iter: 2 fn: 199.3252  Pars:  0.0000000009188 0.9999999990812
#> Iter: 3 fn: 199.3252  Pars:  0.0000000005678 0.9999999994322
#> solnp--> Completed in 3 iterations
#> 
#> Iter: 1 fn: 453.2732  Pars:  0.06791 0.93209
#> Iter: 2 fn: 453.2732  Pars:  0.06788 0.93212
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 451.6012  Pars:  0.05533 0.94467
#> Iter: 2 fn: 451.6012  Pars:  0.05532 0.94468
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 222.6728  Pars:  0.000000003476 0.999999995710
#> Iter: 2 fn: 222.6728  Pars:  0.000000002283 0.999999997717
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 453.2119  Pars:  0.12281 0.87719
#> Iter: 2 fn: 453.2119  Pars:  0.12282 0.87718
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 459.0837  Pars:  0.40415 0.59585
#> Iter: 2 fn: 459.0837  Pars:  0.40415 0.59585
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 224.4303  Pars:  0.05369 0.94631
#> Iter: 2 fn: 224.4303  Pars:  0.05369 0.94631
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 484.9169  Pars:  0.37866 0.62134
#> Iter: 2 fn: 484.9169  Pars:  0.37866 0.62134
#> solnp--> Completed in 2 iterations
#> 
#> Iter: 1 fn: 488.1615  Pars:  0.99999415 0.00000585
#> Iter: 2 fn: 488.1614  Pars:  0.9999997443 0.0000002557
#> solnp--> Completed in 2 iterations
proc.time() - ptm
#>    user  system elapsed 
#>  61.051   3.082 920.514

oracle_parameter <- sim_results$`Oracle Pooled Results`
k_fold_results <- sim_results$`K-fold Results`
oracle_targets <- sim_results$`K Fold Oracle Targets`
```

Of note: these results will be more consistent with higher folds but
here we use 5 so readme builds more quickly for users.

Let’s first look at K fold results:

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
</tr>
</thead>
<tbody>
<tr>
<td style="text-align:right;">
-7.7985083
</td>
<td style="text-align:right;">
0.3650333
</td>
<td style="text-align:right;">
0.6041799
</td>
<td style="text-align:right;">
-8.9827
</td>
<td style="text-align:right;">
-6.6143
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:right;">
100
</td>
<td style="text-align:left;">
X1
</td>
<td style="text-align:right;">
1
</td>
</tr>
<tr>
<td style="text-align:right;">
-5.3648883
</td>
<td style="text-align:right;">
0.5524979
</td>
<td style="text-align:right;">
0.7433020
</td>
<td style="text-align:right;">
-6.8217
</td>
<td style="text-align:right;">
-3.9080
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:right;">
100
</td>
<td style="text-align:left;">
X7
</td>
<td style="text-align:right;">
1
</td>
</tr>
<tr>
<td style="text-align:right;">
-12.4305447
</td>
<td style="text-align:right;">
0.2108756
</td>
<td style="text-align:right;">
0.4592119
</td>
<td style="text-align:right;">
-13.3306
</td>
<td style="text-align:right;">
-11.5305
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:right;">
100
</td>
<td style="text-align:left;">
X1-X7
</td>
<td style="text-align:right;">
1
</td>
</tr>
<tr>
<td style="text-align:right;">
0.7328519
</td>
<td style="text-align:right;">
0.9416103
</td>
<td style="text-align:right;">
0.9703661
</td>
<td style="text-align:right;">
-1.1690
</td>
<td style="text-align:right;">
2.6347
</td>
<td style="text-align:right;">
0.4569019
</td>
<td style="text-align:right;">
100
</td>
<td style="text-align:left;">
Interaction
</td>
<td style="text-align:right;">
1
</td>
</tr>
<tr>
<td style="text-align:right;">
1.5574047
</td>
<td style="text-align:right;">
0.7113273
</td>
<td style="text-align:right;">
0.8434022
</td>
<td style="text-align:right;">
-0.0956
</td>
<td style="text-align:right;">
3.2104
</td>
<td style="text-align:right;">
0.0899167
</td>
<td style="text-align:right;">
100
</td>
<td style="text-align:left;">
X1
</td>
<td style="text-align:right;">
2
</td>
</tr>
<tr>
<td style="text-align:right;">
-0.1970893
</td>
<td style="text-align:right;">
0.5760383
</td>
<td style="text-align:right;">
0.7589719
</td>
<td style="text-align:right;">
-1.6846
</td>
<td style="text-align:right;">
1.2905
</td>
<td style="text-align:right;">
0.8210225
</td>
<td style="text-align:right;">
100
</td>
<td style="text-align:left;">
X5
</td>
<td style="text-align:right;">
2
</td>
</tr>
<tr>
<td style="text-align:right;">
5.6273123
</td>
<td style="text-align:right;">
1.2451360
</td>
<td style="text-align:right;">
1.1158566
</td>
<td style="text-align:right;">
3.4403
</td>
<td style="text-align:right;">
7.8144
</td>
<td style="text-align:right;">
0.0000001
</td>
<td style="text-align:right;">
100
</td>
<td style="text-align:left;">
X1-X5
</td>
<td style="text-align:right;">
2
</td>
</tr>
<tr>
<td style="text-align:right;">
4.2669968
</td>
<td style="text-align:right;">
0.7166617
</td>
<td style="text-align:right;">
0.8465587
</td>
<td style="text-align:right;">
2.6078
</td>
<td style="text-align:right;">
5.9262
</td>
<td style="text-align:right;">
0.0000035
</td>
<td style="text-align:right;">
100
</td>
<td style="text-align:left;">
Interaction
</td>
<td style="text-align:right;">
2
</td>
</tr>
<tr>
<td style="text-align:right;">
-3.4628004
</td>
<td style="text-align:right;">
0.2162710
</td>
<td style="text-align:right;">
0.4650495
</td>
<td style="text-align:right;">
-4.3743
</td>
<td style="text-align:right;">
-2.5513
</td>
<td style="text-align:right;">
0.0000004
</td>
<td style="text-align:right;">
100
</td>
<td style="text-align:left;">
X1
</td>
<td style="text-align:right;">
3
</td>
</tr>
<tr>
<td style="text-align:right;">
-4.2561526
</td>
<td style="text-align:right;">
0.3320851
</td>
<td style="text-align:right;">
0.5762682
</td>
<td style="text-align:right;">
-5.3856
</td>
<td style="text-align:right;">
-3.1267
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:right;">
100
</td>
<td style="text-align:left;">
X7
</td>
<td style="text-align:right;">
3
</td>
</tr>
<tr>
<td style="text-align:right;">
-8.7301492
</td>
<td style="text-align:right;">
0.1102324
</td>
<td style="text-align:right;">
0.3320127
</td>
<td style="text-align:right;">
-9.3809
</td>
<td style="text-align:right;">
-8.0794
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:right;">
100
</td>
<td style="text-align:left;">
X1-X7
</td>
<td style="text-align:right;">
3
</td>
</tr>
<tr>
<td style="text-align:right;">
-1.0111963
</td>
<td style="text-align:right;">
0.6838574
</td>
<td style="text-align:right;">
0.8269567
</td>
<td style="text-align:right;">
-2.6320
</td>
<td style="text-align:right;">
0.6096
</td>
<td style="text-align:right;">
0.2661499
</td>
<td style="text-align:right;">
100
</td>
<td style="text-align:left;">
Interaction
</td>
<td style="text-align:right;">
3
</td>
</tr>
<tr>
<td style="text-align:right;">
-1.4784270
</td>
<td style="text-align:right;">
0.2494608
</td>
<td style="text-align:right;">
0.4994605
</td>
<td style="text-align:right;">
-2.4574
</td>
<td style="text-align:right;">
-0.4995
</td>
<td style="text-align:right;">
0.0364438
</td>
<td style="text-align:right;">
100
</td>
<td style="text-align:left;">
X1
</td>
<td style="text-align:right;">
4
</td>
</tr>
<tr>
<td style="text-align:right;">
-3.8400742
</td>
<td style="text-align:right;">
0.6397796
</td>
<td style="text-align:right;">
0.7998622
</td>
<td style="text-align:right;">
-5.4078
</td>
<td style="text-align:right;">
-2.2724
</td>
<td style="text-align:right;">
0.0000176
</td>
<td style="text-align:right;">
100
</td>
<td style="text-align:left;">
X7
</td>
<td style="text-align:right;">
4
</td>
</tr>
<tr>
<td style="text-align:right;">
-4.7133492
</td>
<td style="text-align:right;">
0.4546646
</td>
<td style="text-align:right;">
0.6742882
</td>
<td style="text-align:right;">
-6.0349
</td>
<td style="text-align:right;">
-3.3918
</td>
<td style="text-align:right;">
0.0000000
</td>
<td style="text-align:right;">
100
</td>
<td style="text-align:left;">
X1-X7
</td>
<td style="text-align:right;">
4
</td>
</tr>
<tr>
<td style="text-align:right;">
0.6051520
</td>
<td style="text-align:right;">
0.5220826
</td>
<td style="text-align:right;">
0.7225528
</td>
<td style="text-align:right;">
-0.8110
</td>
<td style="text-align:right;">
2.0213
</td>
<td style="text-align:right;">
0.4765158
</td>
<td style="text-align:right;">
100
</td>
<td style="text-align:left;">
Interaction
</td>
<td style="text-align:right;">
4
</td>
</tr>
<tr>
<td style="text-align:right;">
0.7227610
</td>
<td style="text-align:right;">
0.9085103
</td>
<td style="text-align:right;">
0.9531581
</td>
<td style="text-align:right;">
-1.1454
</td>
<td style="text-align:right;">
2.5909
</td>
<td style="text-align:right;">
0.4591133
</td>
<td style="text-align:right;">
100
</td>
<td style="text-align:left;">
X1
</td>
<td style="text-align:right;">
5
</td>
</tr>
<tr>
<td style="text-align:right;">
-1.1737772
</td>
<td style="text-align:right;">
1.1133541
</td>
<td style="text-align:right;">
1.0551560
</td>
<td style="text-align:right;">
-3.2418
</td>
<td style="text-align:right;">
0.8943
</td>
<td style="text-align:right;">
0.2531685
</td>
<td style="text-align:right;">
100
</td>
<td style="text-align:left;">
X5
</td>
<td style="text-align:right;">
5
</td>
</tr>
<tr>
<td style="text-align:right;">
-0.1053973
</td>
<td style="text-align:right;">
0.9655426
</td>
<td style="text-align:right;">
0.9826203
</td>
<td style="text-align:right;">
-2.0313
</td>
<td style="text-align:right;">
1.8205
</td>
<td style="text-align:right;">
0.9153243
</td>
<td style="text-align:right;">
100
</td>
<td style="text-align:left;">
X1-X5
</td>
<td style="text-align:right;">
5
</td>
</tr>
<tr>
<td style="text-align:right;">
0.3456190
</td>
<td style="text-align:right;">
1.4373164
</td>
<td style="text-align:right;">
1.1988813
</td>
<td style="text-align:right;">
-2.0041
</td>
<td style="text-align:right;">
2.6954
</td>
<td style="text-align:right;">
0.7522662
</td>
<td style="text-align:right;">
100
</td>
<td style="text-align:left;">
Interaction
</td>
<td style="text-align:right;">
5
</td>
</tr>
</tbody>
</table>

Here we see that X1-X7 are found in 3 folds and X1-X5 are found in two
folds as the most synergistic relationship. This means that, to get to
our target outcome of 15, with precision up to 0.5, these two exposures
are found to most efficiently get to our target outcome under minimal
intervention. These interventions are:

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
9
</td>
<td style="text-align:left;">
X1
</td>
<td style="text-align:left;">
X7
</td>
<td style="text-align:right;">
1.127339
</td>
<td style="text-align:right;">
1.126352
</td>
<td style="text-align:right;">
0.7604973
</td>
<td style="text-align:right;">
0.0426858
</td>
<td style="text-align:right;">
0.7252537
</td>
<td style="text-align:right;">
0.1637156
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
1.175058
</td>
<td style="text-align:right;">
1.214526
</td>
<td style="text-align:right;">
0.0481946
</td>
<td style="text-align:right;">
1.7690362
</td>
<td style="text-align:right;">
0.8406866
</td>
<td style="text-align:right;">
0.1274489
</td>
</tr>
<tr>
<td style="text-align:left;">
13
</td>
<td style="text-align:left;">
X1
</td>
<td style="text-align:left;">
X7
</td>
<td style="text-align:right;">
1.124548
</td>
<td style="text-align:right;">
1.143164
</td>
<td style="text-align:right;">
0.7877847
</td>
<td style="text-align:right;">
0.0426858
</td>
<td style="text-align:right;">
0.7186205
</td>
<td style="text-align:right;">
0.2180422
</td>
</tr>
<tr>
<td style="text-align:left;">
10
</td>
<td style="text-align:left;">
X1
</td>
<td style="text-align:left;">
X7
</td>
<td style="text-align:right;">
1.158695
</td>
<td style="text-align:right;">
1.120035
</td>
<td style="text-align:right;">
0.7806664
</td>
<td style="text-align:right;">
0.0426858
</td>
<td style="text-align:right;">
0.7276892
</td>
<td style="text-align:right;">
0.1428271
</td>
</tr>
<tr>
<td style="text-align:left;">
8
</td>
<td style="text-align:left;">
X1
</td>
<td style="text-align:left;">
X5
</td>
<td style="text-align:right;">
1.124724
</td>
<td style="text-align:right;">
1.266117
</td>
<td style="text-align:right;">
0.0481946
</td>
<td style="text-align:right;">
1.3438657
</td>
<td style="text-align:right;">
0.5771388
</td>
<td style="text-align:right;">
0.3894339
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

To get more power, we do a pooled TMLE over our findings for the
intervention with minimal effort that gets to our target outcome:

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
-3.5934354
</td>
<td style="text-align:right;">
0.0927634
</td>
<td style="text-align:right;">
0.3045709
</td>
<td style="text-align:right;">
-4.1904
</td>
<td style="text-align:right;">
-2.9965
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
-3.5312376
</td>
<td style="text-align:right;">
0.1847595
</td>
<td style="text-align:right;">
0.4298366
</td>
<td style="text-align:right;">
-4.3737
</td>
<td style="text-align:right;">
-2.6888
</td>
<td style="text-align:right;">
0.0000001
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
-7.0006181
</td>
<td style="text-align:right;">
0.0668611
</td>
<td style="text-align:right;">
0.2585751
</td>
<td style="text-align:right;">
-7.5074
</td>
<td style="text-align:right;">
-6.4938
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
0.1240548
</td>
<td style="text-align:right;">
0.2169933
</td>
<td style="text-align:right;">
0.4658254
</td>
<td style="text-align:right;">
-0.7889
</td>
<td style="text-align:right;">
1.0371
</td>
<td style="text-align:right;">
0.8557698
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
the expectations under the sum of individual shifts. Of course, given
inconsistencies in our findings here, the interpretation is difficult
given these findings include shifts for both sets of variables X1-X7 and
X1-X5.

However, when IsoXshift is run with more folds, findings have more
consistency and the pooled result represents a pooled estimate for the
same exposure relationship.

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

</div>
