% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/est_Hn.R
\name{est_hn}
\alias{est_hn}
\title{Estimate Auxiliary Covariate of Full Data Efficient Influence Function}
\usage{
est_hn(gn_exp)
}
\arguments{
\item{gn_exp}{An estimate of the exposure density (a generalized propensity
score) using the output provided by g estimators.}
}
\value{
A \code{data.table} with two columns, containing estimates of the
auxiliary covariate at the natural value of the exposure H(A, W) and at the
shifted value of the exposure H(A + delta, W).
}
\description{
Estimate Auxiliary Covariate of Full Data Efficient Influence Function
}
\details{
Compute an estimate of the auxiliary covariate of the efficient
influence function required to update initial estimates through logistic
tilting models for targeted minimum loss estimation.
}
