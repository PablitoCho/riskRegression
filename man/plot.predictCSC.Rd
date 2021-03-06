% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plot.predictCSC.R
\name{plot.predictCSC}
\alias{plot.predictCSC}
\title{Plot predictions from a Cause-specific Cox proportional hazard regression}
\usage{
\method{plot}{predictCSC}(x, ci = FALSE, band = FALSE, groupBy = "row",
  reduce.data = FALSE, plot = TRUE, digits = 2, alpha = NA, ...)
}
\arguments{
\item{x}{object obtained with the function \code{predictCox}.}

\item{ci}{Logical. If \code{TRUE} display the confidence intervals for the predictions.}

\item{band}{Logical. If \code{TRUE} display the confidence bands for the predictions.}

\item{groupBy}{The grouping factor used to color the prediction curves. Can be \code{"row"}, \code{"strata"}, or \code{"covariates"}.}

\item{reduce.data}{Logical. If \code{TRUE} only the covariates that does take indentical values for all observations are displayed.}

\item{plot}{Logical. Should the graphic be plotted.}

\item{digits}{integer indicating the number of decimal places}

\item{alpha}{transparency of the confidence bands. Argument passed to \code{ggplot2::geom_ribbon}.}

\item{...}{not used. Only for compatibility with the plot method.}
}
\description{
Plot predictions from a Cause-specific Cox proportional hazard regression
}
\examples{
## no strata
d <- sampleData(1e2, outcome = "competing.risks")
m.CSC <- CSC(Hist(time,event)~ X1 + X2 + X6, data = d)

pred.CSC <- predict(m.CSC, newdata = d[1:2,], time = 1:5, cause = 1)
plot(pred.CSC)

pred.CSC <- predict(m.CSC, newdata = d[1:3,],
                    time = 1:5, cause = 1, se = TRUE, keep.newdata = TRUE)


## strata
m.SCSC <- CSC(Hist(time,event)~ strata(X1) + strata(X2) + X6,
data = d)
pred.SCSC <- predict(m.SCSC, time = 1:3, newdata = d[1:4,],
cause = 1, se = TRUE, keep.newdata = TRUE, keep.strata = TRUE)
plot(pred.SCSC, groupBy = "strata")

}
