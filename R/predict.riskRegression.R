#' Predict individual risk.
#' 
#' Extract predictions from a risk prediction model.
#' 
#' 
#' @param object Fitted object obtained with one of \code{ARR}, \code{LRR},
#' \code{riskRegression}.
#' @param newdata A data frame containing predictor variable combinations for
#' which to compute predicted risk.
#' @param \dots not used
#' @author Thomas H. Scheike \email{ts@@biostat.ku.dk}
#' 
#' Thomas A. Gerds \email{tag@@biostat.ku.dk}
#' @references Gerds, TA and Scheike, T and Andersen, PK (2011) Absolute risk
#' regression for competing risks: interpretation, link functions and
#' prediction Research report 11/8. Department of Biostatistics, University of
#' Copenhagen
#' @keywords survival
##' @examples
##' 
##' data(Melanoma)
##' library(prodlim)
##' library(survival)
##' 
##' fit.tarr <- ARR(Hist(time,status)~age+invasion+strata(sex),data=Melanoma,cause=1)
##' predict(fit.tarr,newdata=data.frame(age=48,
##'                      invasion=factor("level.1",
##'                          levels=levels(Melanoma$invasion)),
##'                      sex=factor("Female",levels=levels(Melanoma$sex))))
##' predict(fit.tarr,newdata=data.frame(age=48,
##'                      invasion=factor("level.1",
##'                          levels=levels(Melanoma$invasion)),
##'                      sex=factor("Male",levels=levels(Melanoma$sex))))
##' predict(fit.tarr,newdata=data.frame(age=c(48,58,68),
##'                      invasion=factor("level.1",
##'                          levels=levels(Melanoma$invasion)),
##'                      sex=factor("Male",levels=levels(Melanoma$sex))))
##' predict(fit.tarr,newdata=Melanoma[1:4,])
##'
#' @method predict riskRegression
#' @export 
predict.riskRegression <- function(object,
                                   newdata,
                                   ...){
    # {{{ read design
    Link  <-  object$link
    n  <-  length(object$B.iid)
    ## n is the number of clusters (or number of individuals
    ## if no cluster structure is specified)
    ## if (is.null(object$B.iid)==TRUE && se==TRUE) {
    ## se <- FALSE
    ## warning("This object has no resampling results stored, hence se=TRUE has no effect.\n You may set resample.iid=1 an run again.");
    ## }
    Zcoef <- c(object$timeConstantEffects$coef)
    semi <- !is.null(Zcoef)
    ## m <- stats::model.frame(formula=delete.response(object$design$Terms),
    ## data=newdata,na.action="na.fail")
    tt <- delete.response(object$design$Terms)
    PF <- prodlim::EventHistory.frame(formula(tt),
                                      newdata,
                                      specials=c("timevar","strata","prop","const","tp"),
                                      stripSpecials=c("timevar","prop"),
                                      stripArguments=list("prop"=list("power"=0),"timevar"=list("test"=0)),
                                      stripAlias=list("timevar"=c("strata"),"prop"=c("tp","const")),
                                      stripUnspecials="prop",
                                      specialsDesign=TRUE,
                                      dropIntercept=TRUE,check.formula=FALSE,response=FALSE)
    ## PF <- prodlim::model.design(object$design$Terms,
    ## newdata,
    ## dropIntercept=TRUE,
    ## specialsDesign=TRUE)
    ##  The time-constant effects
    Z <- PF$prop
    factorLevelsZ <- attr(PF$prop,"levels")
    refLevelsZ <- lapply(factorLevelsZ,function(x)x[1])
    if (!(all(colnames(Z) %in% names(object$design$timepower))))
        stop("\nProblem with factor names.\nCheck if the storage type of all factors\nin the original data are compatible with those in newdata\n\nOffending variable(s): ",paste(colnames(Z)[!colnames(Z)%in% names(object$timePower)],collapse=", ")," does not match ",paste(names(object$timePower)[!names(object$timePower)%in%colnames(Z)],collapse=" ,"),".")
    ## The time-varying effects
    X <- PF$timevar
    factorLevelsX <- attr(PF$timevar,"levels")
    refLevelsX <- lapply(factorLevelsX,function(x)x[1])
    if (is.null(Z) && is.null(X))
        nobs <- NROW(newdata)
    else
        nobs <- max(NROW(Z),NROW(X))
    Xcoef  <-  data.frame(object$timeVaryingEffects$coef)
    # }}}
    # {{{ compute the linear predictor
    fittime  <-  object$time
    ntime  <-  NROW(fittime)
    ## intercept
    if (NROW(X)==0){
        ## X <- cbind("Intercept"=1)
        ## remove the time column
        intercept <- t(Xcoef[,-1,drop=FALSE])
        timeVarLP <- matrix(rep(intercept,NROW(Z)),byrow=TRUE,nrow=NROW(Z))
    }
    else {
        X <- cbind("Intercept"=1,X)
        colnamesX <- c("Intercept",colnames(X))
        timeVarLP <- X %*% t(Xcoef[,-1,drop=FALSE]) ## remove the time column
    }
    ## FIXME: manually set extreme values if LP = 0
    ##        should be done in the c-routine
    timeVarLP <- t(apply(timeVarLP,1,function(lp){fixedlp <- lp;
                                                  ## fixedlp[fixedlp==0] <- min(fixedlp)
                                                  fixedlp[fixedlp==0] <- -Inf
                                                  fixedlp}))
    if (semi==TRUE) {
        timepower <- object$design$timepower
        if (any(timepower>0)){
            timeFactor <- matrix(fittime,nrow=length(Zcoef),ncol=length(fittime),byrow=TRUE)
            timeConstLP  <-  Z %*% (Zcoef * (timeFactor^timepower))
        }
        else{
            timeConstLP  <-  colSums(t(Z) * Zcoef)
        }
    }
    else
        timeConstLP <- 0
    LP <- timeConstLP+timeVarLP
    ## tag
    ## added 23 Jan 2016 (16:33)
    ## to fix bug in predictRisk.riskRegression
    if (length(fittime)==1)
        LP <- t(LP)
    # }}}
    # {{{ compute P1
    P1 <- switch(object$link,"relative"={
        pmin(exp(LP),1)
    },"additive"={
        P1=1-exp(-LP)
    },"prop"={
        P1 <- 1-exp(-exp(LP))
    },"logistic"={
        P1 <- exp(LP)/(1+exp(LP))
    })
    # }}}
    # {{{ standard errors and confidence bands

    ##   se.P1  <-  NULL
    ## i.i.d decomposition for computation of standard errors 
    ##   if (se==1) {
    ##     pg <- length(object$gamma); 
    ##     delta <- c();
    ##     for (i in 1:n) {
    ##       tmp <-  as.matrix(X) %*% t(object$B.iid[[i]]) 
    ##       if (semi==TRUE) {
    ##         gammai  <-  matrix(object$gamma.iid[i,],pg,1); 
    ##         tmp.const  <-  Z %*% gammai;
    ##       }
    ##       if (i==0) {
    ##         print(tmp.const);
    ##         if (Link=="additive" || Link == 'aalen'){ 
    ##           print(tmp.const %*% matrix(time,1,nt))
    ##         } else if (Link=="prop"){
    ##           print(tmp.const %*% matrix(1,1,nt));
    ##         } else if (Link=="cox.aalen") {
    ##           tmp  <-  RR * tmp + RR * cumhaz * matrix(tmp.const,nobs,nt);
    ##         }
    ##       }
    ##       if (semi==TRUE){
    ##         if(link=="additive" || link == "aalen") {
    ##           # || Link=="1-additive") {
    ##           tmp <- tmp+tmp.const %*% matrix(time,1,nt)
    ##         } else if (Link=="prop" || Link=="1-additive") {
    ##           tmp <- RR*tmp+RR*matrix(tmp.const,nobs,nt);
    ## 	  ## modification of jeremy's code RR
    ##         } else if (Link=="cox.aalen") {
    ##           tmp  <-  RR * tmp + RR * cumhaz * matrix(tmp.const,nobs,nt);
    ##         }
    ##       }
    ##       delta <- cbind(delta,c(tmp)); 
    ##     }
    ##     se <- apply(delta^2,1,sum)^.5
    ##     if(Link == 'additive' || Link == 'prop'){
    ##       se.P1 <- matrix(se,nobs,nt)*(1-P1) 
    ##     } 
    ##     else if(Link == '1-additive'){
    ##       se.P1 <- matrix(se,nobs,nt)*(P1) 
    ##     } 
    ##     else if (Link == 'logistic'){
    ##       se.P1 <- matrix(se,nobs,nt)*P1/(1+RR)
    ##     } 
    ##     else if (Link == 'aalen' || Link == 'cox.aalen'){
    ##       se.S0 <- matrix(se,nobs,nt)*S0
    ##     }
    ##     ### uniform confidence bands, based on resampling 
    ##     if (uniform==1) {
    ##       mpt  <-  .C('confBandBasePredict',
    ##                   delta = as.double(delta),
    ##                   nObs = as.integer(nobs),
    ##                   nt = as.integer(nt),
    ##                   n = as.integer(n),
    ##                   se = as.double(se),
    ##                   mpt = double(n.sim*nobs),
    ##                   nSims = as.integer(n.sim),
    ##                   PACKAGE="riskRegression")$mpt;
    ##       mpt  <-  matrix(mpt,n.sim,nobs,byrow = TRUE);
    ##       uband  <-  apply(mpt,2,percen,per=1-alpha);
    ##     } else uband <- NULL; 
    ##   } else {
    ##     uband <- NULL;
    ##   }

  # }}}
  # {{{ output
  out <- list(time=fittime,
              ## unif.band=uband,
              ## model=Link,
              ## alpha=alpha,
              risk=P1)
  ## if(se==TRUE){
  ## out$se.risk  <-  se.P1
  ## }
  class(out) <- "predictedRisk"
  out
  # }}}
}
