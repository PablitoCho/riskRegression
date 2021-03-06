#' Cause-specific Cox proportional hazard regression
#' 
#' Interface for fitting cause-specific Cox proportional hazard regression
#' models in competing risk.
#'
#' The causes and their order
#' are determined by \code{prodlim::getStates()} applied to the Hist object.
#' @param formula Either a single \code{Hist} formula or a list of formulas. 
#' If it is a list it must contain as many \code{Hist} formulas as there are
#' causes when \code{survtype="hazard"} and exactly two formulas when \code{survtype="survival"}.
#' If it is a list the first formula is used for the cause of interest specific Cox regression
#' and the other formula(s) either for the other cause specific Cox regression(s) or for the
#' Cox regression of the combined event where each cause counts as event. Note that when only one
#' formula is given the covariates enter in exactly the same way into all Cox regression analyses.  
#' @param data A data in which to fit the models.
#' @param cause The cause of interest. Defaults to the first cause (see Details). 
#' @param survtype Either \code{"hazard"} (the default) or
#' \code{"survival"}.  If \code{"hazard"} fit cause-specific Cox
#' regression models for all causes.  If \code{"survival"} fit one
#' cause-specific Cox regression model for the cause of interest and
#' also a Cox regression model for event-free survival.
#' @param fitter Routine to fit the Cox regression models.
#' If \code{coxph} use \code{survival::coxph} else use \code{rms::cph}.
#' @param ... Arguments given to \code{coxph}.
#' @return \item{models }{a list with the fitted (cause-specific) Cox
#' regression objects} \item{response }{the event history response }
#' \item{eventTimes }{the sorted (unique) event times } \item{survtype }{the
#' value of \code{survtype}} \item{theCause }{the cause of interest. see
#' \code{cause}} \item{causes }{the other causes} %% ...
#' @author Thomas A. Gerds \email{tag@@biostat.ku.dk} and Ulla B. Mogensen
#' @references
#' J Benichou and Mitchell H Gail. Estimates of absolute cause-specific risk
#' in cohort studies. Biometrics, pages 813--826, 1990.
#'
#' T.A. Gerds, T.H. Scheike, and P.K. Andersen. Absolute risk regression for
#' competing risks: interpretation, link functions, and prediction. Statistics
#' in Medicine, 31(29):3921--3930, 2012.
#' 
#' @seealso \code{\link{coxph}}
#' @keywords survival
#' @examples
#' 
##' library(prodlim)
##' library(survival)
##' data(Melanoma)
##' ## fit two cause-specific Cox models
##' ## different formula for the two causes
##' fit1 <- CSC(list(Hist(time,status)~sex,Hist(time,status)~invasion+epicel+age),
##'             data=Melanoma)
##' print(fit1)
##'
##' 
##' 
##' ## model hazard of all cause mortality instead of hazard of type 2 
##' fit1a <- CSC(list(Hist(time,status)~sex+age,Hist(time,status)~invasion+epicel+log(thick)),
##'              data=Melanoma,
##'              survtype="surv")
##' print(fit1a)
##'
##' ## special case where cause 2 has no covariates
##' fit1b <- CSC(list(Hist(time,status)~sex+age,Hist(time,status)~1),
##'              data=Melanoma)
##' print(fit1b)
##' predict(fit1b,cause=1,times=100,newdata=Melanoma)
##' 
##'
##' ## same formula for both causes
##' fit2 <- CSC(Hist(time,status)~invasion+epicel+age,
##'             data=Melanoma)
##' print(fit2)
##'
##' ## combine a cause-specific Cox regression model for cause 2 
##' ## and a Cox regression model for the event-free survival:
##' ## different formula for cause 2 and event-free survival
##' fit3 <- CSC(list(Hist(time,status)~sex+invasion+epicel+age,
##'                  Hist(time,status)~invasion+epicel+age),
##'             survtype="surv",
##'             data=Melanoma)
##' print(fit3)
##' 
##' ## same formula for both causes
##' fit4 <- CSC(Hist(time,status)~invasion+epicel+age,
##'             data=Melanoma,
##'             survtype="surv")
##' print(fit4)
##'
##' ## strata
##' fit5 <- CSC(Hist(time,status)~invasion+epicel+age+strata(sex),
##'             data=Melanoma,
##'             survtype="surv")
##' print(fit5)
##'
##' ## sanity checks
##' 
##' cox1 <- coxph(Surv(time,status==1)~invasion+epicel+age+strata(sex),data=Melanoma)
##' cox2 <- coxph(Surv(time,status!=0)~invasion+epicel+age+strata(sex),data=Melanoma)
##' all.equal(cox1,fit5$models[[1]])
##' all.equal(cox2,fit5$models[[2]])
##'
##' ## predictions
##' ##
##' ## survtype = "hazard": predictions for both causes can be extracted
##' ## from the same fit
##' fit2 <- CSC(Hist(time,status)~invasion+epicel+age, data=Melanoma)
##' predict(fit2,cause=1,newdata=Melanoma[c(17,99,108),],times=c(100,1000,10000))
##' predictRisk(fit2,cause=1,newdata=Melanoma[c(17,99,108),],times=c(100,1000,10000))
##' predictRisk(fit2,cause=2,newdata=Melanoma[c(17,99,108),],times=c(100,1000,10000))
##' predict(fit2,cause=1,newdata=Melanoma[c(17,99,108),],times=c(100,1000,10000))
##' predict(fit2,cause=2,newdata=Melanoma[c(17,99,108),],times=c(100,1000,10000))
##' 
##' ## survtype = "surv" we need to change the cause of interest 
##' library(survival)
##' fit5.2 <- CSC(Hist(time,status)~invasion+epicel+age+strata(sex),
##'             data=Melanoma,
##'             survtype="surv",cause=2)
##' ## now this does not work
##' try(predictRisk(fit5.2,cause=1,newdata=Melanoma,times=4))
##' 
##' ## but this does
##' predictRisk(fit5.2,cause=2,newdata=Melanoma,times=100)
##' predict(fit5.2,cause=2,newdata=Melanoma,times=100)
##' predict(fit5.2,cause=2,newdata=Melanoma[4,],times=100)
##' 
#' @export
CSC <- function(formula,
                data,
                cause,
                survtype="hazard",
                fitter="coxph",
                ## strip.environment
                ...){
    fitter <- match.arg(fitter,c("coxph","cph","phreg"))
    # {{{ type
    survtype <- match.arg(survtype,c("hazard","survival"))
    # }}}
    # {{{ formulae
    if (class(formula)=="formula") formula <- list(formula)
    else if (!length(formula)<=4) stop("Formula can either be a single formula (to be used for both cause specific hazards) or a list of formulae, one for each cause.")
    responseFormula <- reformulate("1", formula[[1]][[2]])
    # }}}
    # {{{ response
    ## require(survival)
    call <- match.call()
    # get information from formula
    mf <- stats::model.frame(update(responseFormula,".~1"), data = data, na.action = na.omit)
    response <- stats::model.response(mf)
    time <- response[, "time"]
    status <- response[, "status"]
    event <- prodlim::getEvent(response)
    # }}}
    # {{{ event times
    eventTimes <- unique(sort(as.numeric(time[status != 0])))
    # }}}
    # {{{ causes
    causes <- prodlim::getStates(response)
    if (survtype=="hazard")
        NC <- length(causes)
    else
        NC <- 2 # cause of interest and overall survival
    if (length(formula)!=NC && length(formula)>1) stop("Wrong number of formulae. Should be ",NC,".")
    if (length(formula)==1) {
        ## warning("The same formula used for all causes")
        formula <- lapply(1:NC,function(x)formula[[1]])
    }
    # }}}
    # {{{ find the cause of interest
    if (missing(cause)){
        theCause <- causes[1]
    }
    else{
        if ((foundCause <- match(as.character(cause),causes,nomatch=0))==0)
            stop(paste("Requested cause: ",cause," Available causes: ", causes))
        else{
            theCause <- causes[foundCause]
        }
    }
    otherCauses <- causes[-match(theCause,causes)]
    # }}}
    # {{{ fit Cox models
    if (survtype=="hazard"){
        nmodels <- NC
    }else {
        nmodels <- 2}
    CoxModels <- lapply(1:nmodels,function(x){
        if (survtype=="hazard"){
            if (x==1)
                causeX <- theCause
            else
                causeX <- otherCauses[x-1]}
        else{
            causeX <- theCause
        }
        EHF <- prodlim::EventHistory.frame(formula=formula[[x]],
                                           data=data,
                                           unspecialsDesign=FALSE,
                                           specialsFactor=FALSE,
                                           specials="strata",
                                           stripSpecials="strata",
                                           stripArguments=list("strata"=NULL),
                                           specialsDesign=FALSE)
        formulaX <- formula[[x]]
        if (is.null(EHF$strata))
            covData <- cbind(EHF$design)
        else
            covData <- cbind(EHF$design,EHF$strata)
        ## response <- stats::model.response(covData)
        time <- as.numeric(EHF$event.history[, "time",drop=TRUE])
        event <- prodlim::getEvent(EHF$event.history)
        if (survtype=="hazard"){
            statusX <- as.numeric(event==causeX)
        }else{
            if (x==1){
                statusX <- 1*(event==causeX)
            }
            else{ ## event-free status 
                statusX <- response[,"status"]
            }
        }
        
        workData <- data.frame(time=time,status=statusX)
        if(fitter=="phreg"){
            if("entry" %in% names(data)){
                stop("data may not contain a column named \"entry\" when using fitter=\"phreg\"")
            }
            workData$entry <- 0
        }
        ## to interprete formula
        ## we need the variables. in case of log(age) terms
        ## covData has wrong names 
        ## workData <- cbind(workData,covData)
        workData <- cbind(workData,data)
        
        response <- paste0("survival::Surv(",if(fitter=="phreg"){"entry,"},"time, status)")
        formulaXX <- as.formula(paste(response,
                                      as.character(delete.response(terms.formula(formulaX)))[[2]],
                                      sep="~"))
        if (fitter=="coxph"){
            fit <- survival::coxph(formulaXX, data = workData,x=TRUE,y=TRUE,...)
        } else if(fitter=="cph") {
            fit <- rms::cph(formulaXX, data = workData,surv=TRUE,x=TRUE,y=TRUE,...)
        } else if(fitter=="phreg") {
            fit <- mets::phreg(formulaXX, data = workData, ...)
        }
        ## fit$formula <- terms(fit$formula)
        ## fit$call$formula <- terms(formulaXX)
        ## fit$call$formula <- fit$formula
        ## fit$call$data <- NULL
        fit$call$formula <- formulaXX
        fit$call$data <- workData
        fit
    })
    if (survtype=="hazard"){
        names(CoxModels) <- paste("Cause",c(theCause,otherCauses))
    }else{
        names(CoxModels) <- c(paste("Cause",theCause),"OverallSurvival")
    }
    # }}}    
    out <- list(call=call,
                models=CoxModels,
                response=response,
                eventTimes=eventTimes,
                survtype=survtype,
                fitter=fitter,
                theCause=theCause,
                causes=c(theCause,otherCauses))
    class(out) <- "CauseSpecificCox"
    out
}


