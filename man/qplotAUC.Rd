% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/qplotAUC.R
\name{qplotAUC}
\alias{qplotAUC}
\title{Plot AUC curve}
\usage{
qplotAUC(x, models, type = "score", lwd = 2, xlim, ylim, axes = TRUE,
  confint = FALSE, ...)
}
\arguments{
\item{x}{Object obtained with \code{Score.list}}

\item{models}{Choice of models to plot}

\item{type}{Character. Either \code{"score"} to show AUC or \code{"contrasts"} to show differences between AUC.}

\item{lwd}{Line width}

\item{xlim}{Limits for x-axis}

\item{ylim}{Limits for y-axis}

\item{axes}{Logical. If \code{TRUE} draw axes.}

\item{confint}{Logical. If \code{TRUE} draw confidence shadows.}

\item{...}{Not yet used}
}
\description{
Plot AUC curve
}
\examples{
library(survival)
d=sampleData(100,outcome="survival")
nd=sampleData(100,outcome="survival")
f1=coxph(Surv(time,event)~X1+X6+X8,data=d,x=TRUE,y=TRUE)
f2=coxph(Surv(time,event)~X2+X5+X9,data=d,x=TRUE,y=TRUE)
xx=Score(list(f1,f2), formula=Surv(time,event)~1,
data=nd, metrics="auc", nullModel=FALSE, times=seq(3:10))
aucgraph <- qplotAUC(xx)
qplotAUC(xx,confint=TRUE)+ggtitle("AUC")+theme_classic()
qplotAUC(xx,type="contrasts")
a=qplotAUC(xx,type="contrasts",confint=TRUE)
a+theme_bw()


}
