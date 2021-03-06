### plot.ate.R --- 
#----------------------------------------------------------------------
## author: Brice Ozenne
## created: apr 28 2017 (14:19) 
## Version: 
## last-updated: maj 19 2017 (17:32) 
##           By: Brice Ozenne
##     Update #: 22
#----------------------------------------------------------------------
## 
### Commentary: 
## 
### Change Log:
#----------------------------------------------------------------------
## 
### Code:

#' @title Plot predictions from a Cause-specific Cox proportional hazard regression
#' @description Plot predictions from a Cause-specific Cox proportional hazard regression
#' 
#' @param x object obtained with the function \code{predictCox}.
#' @param ci Logical. If \code{TRUE} display the confidence intervals for the predictions.
#' @param band Logical. If \code{TRUE} display the confidence bands for the predictions.
#' @param plot Logical. Should the graphic be plotted.
#' @param digits integer indicating the number of decimal places
#' @param alpha transparency of the confidence bands. Argument passed to \code{ggplot2::geom_ribbon}.
#' @param ... not used. Only for compatibility with the plot method.
#' 
#' @examples
#' library(survival)
#' library(rms)
#' 
#' set.seed(10)
#' n <- 1e2
#' 
#' ## Cox model
#' dtS <- sampleData(n,outcome="survival")
#'
#' fit=cph(formula = Surv(time,event)~ X1+X2,data=dtS,y=TRUE,x=TRUE)
#'
#' seqTimes <- sort(unique(fit$y[,1]))
#' seqTimes5 <-seqTimes[seqTimes>5 & seqTimes<10]
#' ateFit <- ate(fit, data = dtS, treatment = "X1", contrasts = NULL,
#'               times = seqTimes, B = 0, band = TRUE, nSim.band = 500, y = TRUE, mc.cores=1)
#' plot(ateFit, band = TRUE, ci = TRUE)
#' 
#' @method plot ate
#' 
#' @export
plot.ate <- function(x,
                     ci = FALSE,
                     band = FALSE,
                     plot = TRUE,
                     digits = 2, alpha = 0.1, ...){

    ## for CRAN check
    Treatment <- NULL
    
    ## initialize and check          
    if(ci && x$se==FALSE){
        stop("argument \'ci\' cannot be TRUE when no standard error have been computed \n",
             "set argment \'se\' to TRUE when calling predictCox \n")
    }
    if(band && x$band==FALSE){
        stop("argument \'band\' cannot be TRUE when the quantiles for the confidence bands have not been computed \n",
             "set argment \'nSim.band\' to a positive integer when calling ate \n")
    }
  
    ## display
    dataL <- copy(x$meanRisk)
    dataL[,row := as.numeric(as.factor(Treatment))]
    setnames(dataL, old = c("lower","upper"), new = c("lowerCI","upperCI"))
    
    gg.res <- predict2plot(dataL = dataL,
                           name.outcome = "meanRisk", # must not contain space to avoid error in ggplot2
                           ci = ci, band = band,
                           groupBy = "Treatment",
                           conf.level = x$conf.level,
                           alpha = alpha,
                           origin = min(x$time))
  
    gg.res$plot <- gg.res$plot + ggplot2::ylab("average absolute risk")
  
    if(plot){
        print(gg.res$plot)
    }
  
  return(invisible(gg.res))
}



#----------------------------------------------------------------------
### plot.ate.R ends here
