### confBandCox.R --- 
#----------------------------------------------------------------------
## author: Brice Ozenne
## created: apr 21 2017 (17:40) 
## Version: 
## last-updated: apr 28 2017 (10:59) 
##           By: Brice Ozenne
##     Update #: 23
#----------------------------------------------------------------------
## 
### Commentary: 
## 
### Change Log:
#----------------------------------------------------------------------
## 
### Code:

#' @title Compute quantiles of a gaussian process
#' @description Compute quantiles of a gaussian process
#' 
#' @param iid The iid decomposition of the estimator over time.
#' @param se The variance of the estimate over time.
#' @param times The time points covered by the confidence bands.
#' @param n.sim The number of simulations used to compute the quantiles.
#' @param conf.level Level of confidence.
#' 
confBandCox <- function(iid, se, times,
                        n.sim, conf.level){  
    # NOTE
    # iid must be (n.new,n.times,n.object)
    #  se must be (n.new,n.times)
    dimTempo <- dim(iid)
    
    new.quantile <- quantileProcess_cpp(nObject = dimTempo[3],
                                        nNew = dimTempo[1],
                                        nSim = n.sim,
                                        iid = aperm(iid, c(2,3,1)),
                                        se = t(se),
                                        confLevel = conf.level)
    
    return(new.quantile)
}


#----------------------------------------------------------------------
### confBandCox.R ends here
