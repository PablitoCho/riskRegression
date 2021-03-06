#' Print function for riskRegression models
#'
#' Print function for riskRegression models
#' @param x Object obtained with ARR, LRR or riskRegression
#' @param times Time points at which to show time-dependent coefficients
#' @param digits Number of digits for all numbers but p-values
#' @param eps p-values smaller than this number are shown as such
#' @param verbose Level of verbosity
#' @param ... not used
#'
#' @method print riskRegression
#' @export
print.riskRegression <- function(x,
                                 times,
                                 digits=3,
                                 eps=10^-4,
                                 verbose=TRUE,
                                 ...) {
  # {{{ echo model type, IPCW and link function
  cat("Competing risks regression model \n")
  cat("\nIPCW weights: ",
      switch(tolower(x$censModel),
             "km"={"marginal Kaplan-Meier" },
             "cox"={"Cox regression model" },                             
             "aalen"={"non-parametric additive Aalen model"}),
      " for the censoring distribution.",sep="")
  summary(x$response)
  cat("\nLink: \'",
      switch(x$link,"prop"="cloglog","logistic"="logistic","additive"="linear","relative"="log"),
      "\' yielding ",
      switch(x$link,
             "prop"="sub-hazard ratios (Fine & Gray 1999)",
             "logistic"="odds ratios",
             "additive"="absolute risk differences",
             "relative"="absolute risk ratios"),
      ## ", see help(riskRegression).\n",
      sep="")

  # }}}
  # {{{ find covariates and factor levels 

  cvars <- x$design$const
  if (Ipos <- match("Intercept",x$design$timevar,nomatch=0))
      tvars <- x$design$timevar[-Ipos]
  else
      tvars <- x$design$timevar
  Flevels <- x$factorLevels

  # }}}
  # {{{ time varying coefs
  if (length(tvars)>0){
      cat("\nCovariates with time-varying effects:\n\n")
      nix <- lapply(tvars,function(v){
          if (is.null(flevs <- Flevels[[v]])){
              cat(" ",v," (numeric)\n",sep="")
          }
          else{
              cat(" ",v," (factor with levels: ",paste(flevs,collapse=", "),")\n",sep="")
          }
      })
  } else{
      cat("\nNo covariates with time-varying coefficient specified.\n")
  }
  ## cat("The column 'Intercept' is the baseline risk")
  ## cat(" where all the covariates have value zero\n\n")
  ## if (missing(times)) times <- quantile(x$time)
  ## showTimes <- prodlim::sindex(eval.times=times,jump.times=x$time)
  ## showMat <- signif(exp(x$timeVaryingEffects$coef[showTimes,-1,drop=FALSE]),digits)
  ## rownames(showMat) <- signif(x$timeVaryingEffects$coef[showTimes,1],2)
  ## print(showMat)
  ## cat("\nShown are selected time points, use\n\nplot.riskRegression\n\nto investigate the full shape.\n\n")
  # }}}
  # {{{ time constant coefs
  ## if (!is.null(cvars)){
  ## cat("\nCovariates with time-constant effects:\n\n")
  ## nix <- lapply(cvars,function(v){
  ## if (is.null(flevs <- Flevels[[v]])){
  ## cat(" ",v," (numeric)\n",sep="")
  ## }
  ## else{
  ## cat(" ",v," (factor with levels: ",paste(flevs,collapse=", "),")\n",sep="")
  ## }
  ## })
  ## }
  if (is.null(x$timeConstantEffects$coef)){
      cat("\nNo time constant regression coefficients in model.\n")
      coefMat <- NULL
  }
  else{
      cat("\nTime constant regression coefficients:\n")
      const.coef <- x$timeConstantEffects$coef
      const.se <- sqrt(diag(x$timeConstantEffects$var))
      wald <- const.coef/const.se
      waldp <- (1 - pnorm(abs(wald))) * 2
      format.waldp <- format.pval(waldp,digits=digits,eps=eps)
      names(format.waldp) <- names(waldp)
      format.waldp[const.se==0] <- NA
      if (any(const.se==0))
          warning("Some standard errors are zero. It seems that the model did not converge")
      coefMat <- do.call("rbind",lapply(cvars,function(v){
          covname <- strsplit(v,":")[[1]][[1]]
          if (is.null(Flevels[[covname]])){
              out <- c(v,signif(c(const.coef[v],exp(const.coef[v]),const.se[v],wald[v]),digits),format.waldp[v])
          }
          else{
              rlev <- x$refLevels[[covname]]
              out <- do.call("rbind",lapply(Flevels[[covname]],function(l){
                  V <- paste(covname,l,sep=":")
                  if (match(V,paste(covname,rlev,sep=":"),nomatch=FALSE))
                      c(paste(covname,rlev,sep=":"),"--","--","--","--","--")
                  else
                      c(V,signif(c(const.coef[V],exp(const.coef[V]),const.se[V],wald[V]),digits),format.waldp[V])
              }))
          }
          out
      }))
      if (!is.null(coefMat)){
          colnames(coefMat) <- c("Factor","Coef","exp(Coef)","StandardError","z","Pvalue")
          rownames(coefMat) <- rep("",NROW(coefMat))
          print(coefMat,quote=FALSE,right=TRUE)
          cat(paste("\n\nNote: The values exp(Coef) are",switch(x$link,"prop"="sub-hazard ratios (Fine & Gray 1999)","logistic"="odds ratios","additive"="absolute risk differences","relative"="absolute risk ratios")),"\n")
          tp <- x$design$timepower!=0
          if (any(tp))
              cat(paste("\n\nNote:The coeffient(s) for the variable(s)\n",
                        paste(names(x$design$timepower)[tp],collapse=", "),
                        " are to be interpreted as effect per unit multiplied by time^power.\n",sep=""))
      }
  }
  # }}}
  invisible(coefMat)
}
