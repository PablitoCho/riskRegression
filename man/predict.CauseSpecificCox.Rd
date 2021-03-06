% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/predict.CauseSpecificCox.R
\name{predict.CauseSpecificCox}
\alias{predict.CauseSpecificCox}
\title{Predicting absolute risk from cause-specific Cox models}
\usage{
\method{predict}{CauseSpecificCox}(object, newdata, times, cause,
  landmark = NA, keep.times = 1L, keep.newdata = 1L, keep.strata = 1L,
  se = FALSE, band = FALSE, iid = FALSE, average.iid = FALSE,
  nSim.band = 10000, logTransform = FALSE, productLimit = TRUE,
  conf.level = 0.95, store.iid = "full", ...)
}
\arguments{
\item{object}{The fitted cause specific Cox model}

\item{newdata}{A data frame containing the values of the variables
in the right hand side of 'coxph' for each subject.}

\item{times}{Vector of times at which to return the estimated
absolute risk.}

\item{cause}{Identifies the cause of interest among the competing
events.}

\item{landmark}{the starting time for the computation of the cumulative risk}

\item{keep.times}{Logical. If \code{TRUE} add the evaluation times
to the output.}

\item{keep.newdata}{Logical. If \code{TRUE} add the value of the covariates used to make the prediction in the output list.}

\item{keep.strata}{Logical. If \code{TRUE} add the value of the strata used to make the prediction in the output list.}

\item{se}{Logical. If \code{TRUE} add the standard errors to the output.}

\item{band}{Logical. If \code{TRUE} add the confidence band to the output.}

\item{iid}{Logical. If \code{TRUE} add the influence function to the output.}

\item{average.iid}{Logical. If \code{TRUE} add the average of the influence function over \code{newdata} to the output.}

\item{nSim.band}{the number of simulations used to compute the quantiles
for the confidence bands.}

\item{logTransform}{Should the confidence intervals/bands be computed on the
log(-log) scale and be backtransformed.
Otherwise they are computed on the original scale and truncated (if necessary).}

\item{productLimit}{Logical. If true the survival is computed using the product limit estimator.
Otherwise the exponential approximation is used (i.e. exp(-cumulative hazard)).}

\item{conf.level}{Level of confidence.}

\item{store.iid}{Implementation used to estimate the influence function and the standard error.
Can be \code{"full"} or \code{"minimal"}. See the details section of \code{\link{calcSeCSC}}.}

\item{...}{not used}
}
\value{
A list containing:
\itemize{
\item{absRisk}: (data table) the predictions for each subject (in rows) and each time (in columns).
\item{absRisk.se}: (data table) the standard errors of the predictions.
\item(absRisk.iid): (array) the value of the influence of each subject used to fit the object (dim 3)
for each subject in newdata (dim 1) and each time (dim 2).
\item{times}: (vector) the evaluation times.
}
}
\description{
Apply formula to combine two or more Cox models into absolute risk (cumulative incidence function)
}
\details{
Note: for Cox regression models with time varying
    covariates it does not make sense to use this function, because
    the predicted risk has to be a measurable function of the data
    available at the time origin.

When setting \code{logTransform} to \code{TRUE}, the standard error that is returned is 
before back-transformation to the original scale.
}
\examples{
set.seed(5)
d <- sampleData(80,outcome="comp")
nd <- sampleData(4,outcome="comp")
d$time <- round(d$time,1)
ttt <- sort(sample(x = unique(d$time), size = 10))

# coxph function
CSC.fit <- CSC(Hist(time,event)~ X3+X8,data=d, method = "breslow")
x= predict(CSC.fit,newdata=nd,times=1:10,cause=1,se=1L)
px=print(x)
px
x2 = predict(CSC.fit,newdata=nd,times=1:10,cause=1,se=1L,
           logTransform = TRUE)

predCSC <- predict(CSC.fit, newdata = d, cause = 2, times = ttt)
predCSC.se <- predict(CSC.fit, newdata = d[1:5,], cause = 2, times = ttt,
                      se = TRUE,keep.newdata=TRUE)
predCSC.iid <- predict(CSC.fit, newdata = d[1:5,],
                       cause = 2, times = ttt, iid = TRUE)

# predCSC.se$absRisk.se
# sqrt(apply(predCSC.iid$absRisk.iid[,1,]^2,1,function(x){sum(x)}))
## strata
CSC.fit.s <- CSC(list(Hist(time,event)~ strata(X1)+X2+X9,
 Hist(time,event)~ X2+strata(X4)+X8+X7),data=d, method = "breslow")
predict(CSC.fit.s,cause=1,times=ttt,se=1L)
# cph function
CSC.cph <- CSC(Hist(time,event)~ X1+X2,data=d, method = "breslow", fitter = "cph")

predict(CSC.cph, newdata = d, cause = 2, times = ttt)

# landmark analysis
T0 <- 1
predCSC_afterT0 <- predict(CSC.fit, newdata = d, cause = 2, times = ttt[ttt>T0], landmark = T0)
predCSC_afterT0

}
\author{
Brice Ozenne broz@sund.ku.dk, Thomas A. Gerds
    tag@biostat.ku.dk
}
