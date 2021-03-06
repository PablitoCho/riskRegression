% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/getCoxInfo.R
\name{CoxStrata}
\alias{CoxStrata}
\alias{CoxStrata.cph}
\alias{CoxStrata.coxph}
\alias{CoxStrata.phreg}
\title{Define the strata for a new dataset}
\usage{
CoxStrata(object, data, sterms, stratavars, levels, stratalevels)

\method{CoxStrata}{coxph}(object, data, sterms, stratavars, levels,
  stratalevels)

\method{CoxStrata}{coxph}(object, data, sterms, stratavars, levels,
  stratalevels)

\method{CoxStrata}{phreg}(object, data, sterms, stratavars, levels,
  stratalevels)
}
\arguments{
\item{object}{The fitted Cox regression model object either
obtained with \code{coxph} (survival package), \code{cph}
(rms package), or \code{phreg} (mets package).}

\item{data}{a \code{data.frame} or a \code{data.table}}

\item{sterms}{terms in the formula corresponding to the strata variables}

\item{stratavars}{the name of the variables used to define the strata}

\item{levels}{the strata levels that have been used to fit the Cox model}

\item{stratalevels}{a named list containing for each variable used to form the strata all its possible levels}
}
\description{
Define the strata in a dataset to match those of a stratified Cox model
}
\details{
if no strata variables returns a vector of \code{"1"} (factor).
}
\examples{
\dontrun{
d <- sampleData(1e2, outcome = "survival")
d$entry <- 0
d$id <- 1:NROW(d)

##
library(survival)
mCoxS <- coxph(Surv(time, event) ~ strata(X1)+strata(X2), data = d, x = TRUE, y = TRUE)
resInfo <- CoxVariableName(mCoxS)
Ostrata <- CoxStrata(mCoxS, stratavars = resInfo$stratavars)
CoxStrata(mCoxS, data = d, sterms = resInfo$sterms, stratavars = resInfo$stratavars, 
          levels = levels(Ostrata), stratalevels = resInfo$stratalevels)

##
library(rms)
mCoxS <- cph(Surv(time, event) ~ strat(X1)+strat(X2), data = d, y = TRUE)
resInfo <- CoxVariableName(mCoxS)
Ostrata <- CoxStrata(mCoxS, stratavars = resInfo$stratavars)
CoxStrata(mCoxS, data = d, sterms = resInfo$sterms, stratavars = resInfo$stratavars, 
          levels = levels(Ostrata), stratalevels = resInfo$stratalevels)
          
##
library(mets)
mCoxS <- phreg(Surv(entry, time, event) ~ strata(X1)+X2+cluster(id), data = d)
resInfo <- CoxVariableName(mCoxS)
Ostrata <- CoxStrata(mCoxS, stratavars = resInfo$stratavars)
CoxStrata(mCoxS, data = d, sterms = resInfo$sterms, stratavars = resInfo$stratavars, 
          levels = levels(Ostrata), stratalevels = resInfo$stratalevels)
}
}
\author{
Brice Ozenne broz@sund.ku.dk
}
