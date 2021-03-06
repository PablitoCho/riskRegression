### predictRisk.R --- 
#----------------------------------------------------------------------
## author: Thomas Alexander Gerds
## created: Jun  6 2016 (09:35) 
## Version: 
## last-updated: maj 18 2017 (22:21) 
##           By: Brice Ozenne
##     Update #: 104
#----------------------------------------------------------------------
## 
### Commentary: 
## 
### Change Log:
#----------------------------------------------------------------------
## 
### Code:
library(riskRegression)
library(testthat)
library(rms)
library(survival)
library(mstate)
tmat <- trans.comprisk(2, names = c("0", "1", "2"))

context("Risk prediction")

# {{{ 1- [predictCox,CSC] Check prediction after and before the last event 
cat("prediction before and after the last event \n")

data(Melanoma)
times1 <- unique(Melanoma$time)
times2 <- c(0,0.9*min(times1),times1*1.1)
dataset1 <- Melanoma[sample.int(n = nrow(Melanoma), size = 12),]

#### no strata
fit.coxph <- coxph(Surv(time,status == 1) ~ thick*age, data = Melanoma, y = TRUE, x = TRUE)
fit.cph <- cph(Surv(time,status == 1) ~ thick*age, data = Melanoma, y = TRUE, x = TRUE)
fit.CSC <- CSC(Hist(time,status) ~ thick*age, data = Melanoma, fitter = "cph")

test_that("Prediction with Cox model - NA after last event",{
  test.times <- max(Melanoma$time) + c(-1e-1,0,1e-1)
  
  prediction <- predictCox(fit.coxph, type = c("hazard","cumhazard","survival"), times = test.times, newdata = Melanoma[1,,drop = FALSE])
  expect_equal(as.vector(is.na(prediction$hazard)), c(FALSE, FALSE, TRUE))
  expect_equal(as.vector(is.na(prediction$cumhazard)), c(FALSE, FALSE, TRUE))
  expect_equal(as.vector(is.na(prediction$survival)), c(FALSE, FALSE, TRUE))
  
  prediction <- predictCox(fit.cph, type = c("hazard","cumhazard","survival"), times = test.times, newdata = Melanoma[1,,drop = FALSE])
  expect_equal(as.vector(is.na(prediction$hazard)), c(FALSE, FALSE, TRUE))
  expect_equal(as.vector(is.na(prediction$cumhazard)), c(FALSE, FALSE, TRUE))
  expect_equal(as.vector(is.na(prediction$survival)), c(FALSE, FALSE, TRUE))
})

test_that("Prediction with Cox model - no event before prediction time",{
  test.times <- min(Melanoma$time)-1e-5
  
  prediction <- predictCox(fit.coxph, type = c("hazard","cumhazard","survival"), times = test.times, newdata = Melanoma[1,,drop = FALSE])
  expect_equal(as.double(prediction$hazard), 0)
  expect_equal(as.double(prediction$cumhazard), 0)
  expect_equal(as.double(prediction$survival), 1)
  
  prediction <- predictCox(fit.cph, type = c("hazard","cumhazard","survival"), times = test.times, newdata = Melanoma[1,,drop = FALSE])
  expect_equal(as.double(prediction$hazard), 0)
  expect_equal(as.double(prediction$cumhazard), 0)
  expect_equal(as.double(prediction$survival), 1)
})

test_that("Prediction with CSC - NA after last event",{
  test.times <- max(Melanoma$time) + c(-1e-1,0,1e-1)
  
  prediction <- predict(fit.CSC, times = test.times, newdata = Melanoma[1,,drop = FALSE], cause = 1)
  expect_equal(as.vector(is.na(prediction$absRisk)), c(FALSE, FALSE, TRUE))
})

test_that("Prediction with CSC - no event before prediction time",{
  test.times <- min(Melanoma$time)-1e-5
  
  prediction <- predict(fit.CSC, times = test.times, newdata = Melanoma[1,,drop = FALSE], cause = 1)
  expect_equal(as.double(prediction$absRisk), 0)
})

test_that("Prediction - last event censored",{
  nData <- length(Melanoma$event)
  
  fit.coxph <- coxph(Surv(time,status == 1) ~ thick*age, data = Melanoma, y = TRUE, x = TRUE)
  fit.cph <- cph(Surv(time,status == 1) ~ thick*age, data = Melanoma, y = TRUE, x = TRUE)
  fit.CSC <- CSC(Hist(time,status) ~ thick*age, data = Melanoma, fitter = "cph")

  vec.times <- sort(c(Melanoma$time, Melanoma$time+1/2))[c(1,10,50,80,125,400,409,410)]
  p1 <- predictCox(fit.coxph, times = vec.times, newdata = Melanoma[1:5,])
  p2 <- predictCox(fit.cph, times = vec.times, newdata = Melanoma[1:5,])
  p3 <- rbind(c(1,0.9901893,0.8210527,0.685011,0.5877866,0.3577521,0.3577521,NA),
              c(1,0.9969463,0.9406704,0.8892678,0.8480293,0.7269743,0.7269743,NA),
              c(1,0.9973169,0.9476885,0.9020417,0.8651891,0.7556985,0.7556985,NA),
              c(1,0.9946451,0.8981872,0.8138074,0.7487177,0.5713246,0.5713246,NA),
              c(1,0.9830808,0.7108797,0.5195539,0.3986327,0.1687930,0.1687930,NA)
              )
  # pec::predictSurvProb(fit.coxph, times = vec.times, newdata = Melanoma[1:5,])            
  # predictSurvProb automatically sort the results
  
  expect_equal(p1,p2, tolerance = 1e-4)
  expect_equal(p1$survival, unname(p3), tolerance = 1e-7)

  survLast <- p1$survival[,6]
  survLastM1 <- p1$survival[,7]
  expect_equal(unname(survLast-survLastM1==0), rep(TRUE, 5)) # check that survival decrease at the last time
})

test_that("Prediction - last event is a death",{
  nData <- length(Melanoma$event)
  Melanoma2 <- Melanoma
  Melanoma2$status[nData] <- 1
  fit.coxph <- coxph(Surv(time,status == 1) ~ thick*age, data = Melanoma2, y = TRUE, x = TRUE)
  fit.cph <- cph(Surv(time,status == 1) ~ thick*age, data = Melanoma2, y = TRUE, x = TRUE)
  fit.CSC <- CSC(Hist(time,status) ~ thick*age, data = Melanoma2, fitter = "cph")
  
  vec.times <- sort(c(Melanoma$time, Melanoma$time+1/2))[c(1,10,50,80,125,400,409,410)]
  p1 <- predictCox(fit.coxph, times = vec.times, newdata = Melanoma[1:5,])
  p2 <- predictCox(fit.cph, times = vec.times, newdata = Melanoma[1:5,])
  p3 <-  rbind(c(1, 0.9901893, 0.8210527, 0.6850110, 0.5877866, 0.3577521, 0.020881916, NA),
               c(1, 0.9969463, 0.9406704, 0.8892678, 0.8480293, 0.7269743, 0.301151229, NA),
               c(1, 0.9973169, 0.9476885, 0.9020417, 0.8651891, 0.7556985, 0.348439663, NA),
               c(1, 0.9946451, 0.8981872, 0.8138074, 0.7487177, 0.5713246, 0.121605930, NA),
               c(1, 0.9830808, 0.7108797, 0.5195539, 0.3986327, 0.1687930, 0.001235699, NA)
               )
  #pec::predictSurvProb(fit.coxph, times = vec.times, newdata = Melanoma[1:5,])
  # predictSurvProb automatically sort the results
  
  expect_equal(p1,p2, tolerance = 1e-4)
  expect_equal(p1$survival, unname(p3), tolerance = 1e-7)
  
  survLast <- p1$survival[,7]
  survLastM1 <- p1$survival[,6]
  expect_equal(unname(survLast-survLastM1<0), rep(TRUE, 5)) # check that survival decrease at the last time
})

#### strata
fit.coxph <- coxph(Surv(time,status == 1) ~ thick + strata(invasion) + strata(ici), data = Melanoma, y = TRUE, x = TRUE)
fit.cph <- cph(Surv(time,status == 1) ~ thick + strat(invasion) + strat(ici), data = Melanoma, y = TRUE, x = TRUE)
fit.CSC <- CSC(Hist(time,status) ~ thick + strat(invasion) + strat(ici), data = Melanoma, fitter = "cph")

# take one observation from each strata
data.test <- data.table(Melanoma)[, .SD[1], by = c("invasion", "ici")]
setkeyv(data.test, c("invasion","ici"))

# identify the last event time for each strata
epsilon <- min(diff(unique(fit.coxph$y[,"time"])))/10
pred.coxph <- predictCox(fit.coxph, keep.strata = TRUE, keep.times = TRUE)
baseHazStrata <- as.data.table(pred.coxph[c("time","hazard","cumhazard","strata","survival")])
dt.times <- baseHazStrata[, .(beforeLastTime = time[.N]-epsilon, LastTime = time[.N], afterLastTime = time[.N]+epsilon), by = strata]

test_that("Prediction with Cox model (strata) - NA after last event",{
  for(Ttempo in 1:nrow(dt.times)){
    test.times <- sort(unlist(dt.times[Ttempo, .(beforeLastTime, LastTime, afterLastTime)]))
    
    prediction <- predictCox(fit.coxph, type = c("hazard","cumhazard","survival"), times = test.times, newdata = data.test)
    expect_equal(is.na(prediction$hazard[Ttempo,]), c(FALSE, FALSE, TRUE))
    expect_equal(is.na(prediction$cumhazard[Ttempo,]), c(FALSE, FALSE, TRUE))
    expect_equal(is.na(prediction$survival[Ttempo,]), c(FALSE, FALSE, TRUE))
    
    prediction <- predictCox(fit.cph, type = c("hazard","cumhazard","survival"), times = test.times, newdata = data.test)
    expect_equal(is.na(prediction$hazard[Ttempo,]), c(FALSE, FALSE, TRUE))
    expect_equal(is.na(prediction$cumhazard[Ttempo,]), c(FALSE, FALSE, TRUE))
    expect_equal(is.na(prediction$survival[Ttempo,]), c(FALSE, FALSE, TRUE))
    }
})

test_that("Prediction with CSC (strata) - NA after last event",{
  for(Ttempo in 1:nrow(dt.times)){
    test.times <- sort(unlist(dt.times[Ttempo, .(beforeLastTime, LastTime, afterLastTime)]))
    
    prediction <- predict(fit.CSC, times = test.times, newdata = data.test, cause = 1)
    expect_equal(unname(is.na(prediction$absRisk[Ttempo,])), c(FALSE, FALSE, TRUE))
    expect_equal(unname(is.na(prediction$absRisk[Ttempo,])), c(FALSE, FALSE, TRUE))
    expect_equal(unname(is.na(prediction$absRisk[Ttempo,])), c(FALSE, FALSE, TRUE))
  }
})

test_that("Prediction with Cox model (strata) - no event before prediction time",{
  test.times <- min(Melanoma$time)-1e-5
  
  prediction <- predictCox(fit.coxph, type = c("hazard","cumhazard","survival"), times = test.times, newdata = Melanoma[1,,drop = FALSE])
  expect_equal(as.double(prediction$hazard), 0)
  expect_equal(as.double(prediction$cumhazard), 0)
  expect_equal(as.double(prediction$survival), 1)
  
  prediction <- predictCox(fit.cph, type = c("hazard","cumhazard","survival"), times = test.times, newdata = Melanoma[1,,drop = FALSE])
  expect_equal(as.double(prediction$hazard), 0)
  expect_equal(as.double(prediction$cumhazard), 0)
  expect_equal(as.double(prediction$survival), 1)
})

test_that("Prediction with CSC (strata)  - no event before prediction time",{
  test.times <- min(Melanoma$time)-1e-5
  
  prediction <- predict(fit.CSC, times = test.times, newdata = Melanoma[1,,drop = FALSE], cause = 1)
  expect_equal(as.double(prediction$absRisk), 0)
})
# }}}

# {{{ 2- [predictCox] Dealing with weights
cat("weigthed Cox model \n")
set.seed(10)
data(Melanoma)
wdata <- runif(nrow(Melanoma), 0, 1)
times1 <- unique(Melanoma$time)

fit.coxph <- coxph(Surv(time,status == 1) ~ thick*age, data = Melanoma, y = TRUE, x = TRUE)
fitW.coxph <- coxph(Surv(time,status == 1) ~ thick*age, data = Melanoma, weights = wdata, y = TRUE, x = TRUE)

fit.cph <- cph(Surv(time,status == 1) ~ thick*age, data = Melanoma, y = TRUE, x = TRUE)
fitW.cph <- cph(Surv(time,status == 1) ~ thick*age, data = Melanoma, y = TRUE, x = TRUE, weights = wdata)

# res <- predictCox(fit.coxph, times = Melanoma$time, newdata = Melanoma)
test_that("Prediction with Cox model - weights",{
  expect_error(resW <- predictCox(fitW.coxph, times = Melanoma$time, newdata = Melanoma))
  expect_error(resW <- predictCox(fitW.cph, times = Melanoma$time, newdata = Melanoma))
})
# resGS <- survival:::predict.coxph(fit.coxph, times = times1, newdata = Melanoma, type = "expected")
# resGSW <- survival:::predict.coxph(fitW.coxph, times = times1, newdata = Melanoma, type = "expected")

# expect_equal(diag(res$cumhazard), resGS)
# expect_equal(diag(resW$cumhazard), resGSW)
# }}}

# {{{ 4- [predictCox,CSC] Check influence of the order of the prediction times
cat("Order of the prediction times \n")
data(Melanoma)
times2 <- sort(c(0,0.9*min(Melanoma$time),Melanoma$time[5],max(Melanoma$time)*1.1))
newOrder <- sample.int(length(times2),length(times2),replace = FALSE)

test_that("Prediction with Cox model - sorted vs. unsorted times",{
  fit.coxph <- coxph(Surv(time,status == 1) ~ thick, data = Melanoma, x = TRUE, y = TRUE)
  predictionUNS <- predictCox(fit.coxph, times = times2[newOrder], newdata = Melanoma[1:5,], keep.times = FALSE)
  predictionS <- predictCox(fit.coxph, times = times2, newdata = Melanoma[1:5,], keep.times = FALSE)
  class(predictionS) <- NULL
  # predictSurvProb(fit.coxph, times = times2[newOrder], newdata = Melanoma)
  # predictSurvProb(fit.coxph, times = times2, newdata = Melanoma)
  expect_equal(predictionS[predictionUNS$type],
               lapply(predictionUNS[predictionUNS$type], function(x){x[,order(newOrder)]}))
  
  fit.cph <- cph(Surv(time,status == 1) ~ thick, data = Melanoma, y = TRUE, x = TRUE)
  predictionUNS <- predictCox(fit.cph, times = times2[newOrder], newdata = Melanoma[1:5,], keep.times = FALSE)
  predictionS <- predictCox(fit.cph, times = times2, newdata = Melanoma[1:5,], keep.times = FALSE)
  class(predictionS) <- NULL
  expect_equal(predictionS[predictionS$type], lapply(predictionUNS[predictionUNS$type], function(x){x[,order(newOrder)]}))
})

test_that("Prediction with CSC - sorted vs. unsorted times",{
  fit.CSC <- CSC(Hist(time,status) ~ thick, data = Melanoma)
  predictionUNS <- predict(fit.CSC, times = times2[newOrder], newdata = Melanoma, cause = 1, keep.times = FALSE)
  predictionS <- predict(fit.CSC, times = times2, newdata = Melanoma, cause = 1, keep.times = FALSE)
  expect_equal(predictionS$absRisk, predictionUNS$absRisk[,order(newOrder)])
})

test_that("Prediction with Cox model (strata) - sorted vs. unsorted times",{
    times2 <- c(100,200,500)
    newOrder <- c(3,2,1)
    fit.coxph <- coxph(Surv(time,status == 1) ~ thick + strata(invasion), data = Melanoma, y = TRUE,  x = TRUE)
    predictionUNS <- predictCox(fit.coxph,times = c(500,200,100),newdata = Melanoma[1,],keep.times = FALSE,keep.strata = FALSE)
    predictionS <- predictCox(fit.coxph,times = c(100,200,500),newdata = Melanoma[1,],keep.times = FALSE,keep.strata = FALSE)
    expect_equal(predictionS[predictionS$type], lapply(predictionUNS[predictionUNS$type], function(x){x[,order(c(500,200,100)),drop=FALSE]}))
    fit.cph <- cph(Surv(time,status == 1) ~ thick + strat(invasion), data = Melanoma, y = TRUE, x = TRUE)
    predictionUNS <- predictCox(fit.cph,times = c(500,200,100),newdata = Melanoma[1,],keep.times = FALSE,keep.strata = FALSE)
    predictionS <- predictCox(fit.cph,times = c(100,200,500),newdata = Melanoma[1,],keep.times = FALSE,keep.strata = FALSE)
    expect_equal(predictionS[predictionS$type], lapply(predictionUNS[predictionUNS$type], function(x){x[,order(c(500,200,100)),drop=FALSE]}))
})
# na.omit(predictionS$hazard)

test_that("Prediction with CSC (strata) - sorted vs. unsorted times",{
  fit.CSC <- CSC(Hist(time,status) ~ thick + strat(invasion), data = Melanoma)
  predictionUNS <- predict(fit.CSC, times = times2[newOrder], newdata = Melanoma, cause = 1)
  predictionS <- predict(fit.CSC, times = times2, newdata = Melanoma, cause = 1)
  expect_equal(predictionS$absRisk, predictionUNS$absRisk[,order(newOrder)])
})

test_that("Deal with negative time points",{
    expect_equal(unname(predictCox(fit.coxph, times = -1, newdata = dataset1)$survival),
                 matrix(1,nrow = nrow(dataset1), ncol = 1))
    expect_equal(unname(predict(fit.CSC, times = -1, newdata = dataset1, cause = 1)$absRisk),
                 matrix(0,nrow = nrow(dataset1), ncol = 1))
})

test_that("Deal with NA in times",{
  expect_error(predictionS <- predictCox(fit.coxph, times = c(times2,NA), newdata = Melanoma))
  expect_error(predictionS <- predict(fit.CSC, times = c(times2,NA), newdata = Melanoma, cause = 1))
})
# }}}

# {{{ 5- [predictCox] Check baseline hazard
cat("Estimation of the baseline hazard \n")
data(Melanoma)

test_that("baseline hazard - match basehaz results",{
  fit.coxph <- coxph(Surv(time,status == 1) ~ thick + invasion + ici, data = Melanoma, y = TRUE, x = TRUE)
  fit.cph <- cph(Surv(time,status == 1) ~ thick + invasion + ici, data = Melanoma, y = TRUE, x = TRUE)
  
  expect_equal(predictCox(fit.coxph, centered = FALSE)$cumhazard, 
               basehaz(fit.coxph, centered = FALSE)$hazard, tolerance = 1e-8)
  expect_equal(predictCox(fit.coxph, centered = TRUE)$cumhazard, 
               basehaz(fit.coxph, centered = TRUE)$hazard, tolerance = 1e-8)
  expect_equal(predictCox(fit.cph)$cumhazard, 
               basehaz(fit.cph)$hazard, tolerance = 1e-8)
  
  ## possible differences due to different fit - coef(fit.coxph)-coef(fit.cph)
  expect_equal(predictCox(fit.cph),
               predictCox(fit.coxph, centered = TRUE), 
               tolerance = 100*max(abs(coef(fit.coxph)-coef(fit.cph))))
})

#### strata
test_that("baseline hazard (strata) - order of the results",{
  fit.coxph <- coxph(Surv(time,status == 1) ~ thick + strata(invasion) + strata(ici), data = Melanoma, y = TRUE, x = TRUE)
  fit.cph <- cph(Surv(time,status == 1) ~ thick + strat(invasion) + strat(ici), data = Melanoma, y = TRUE, x = TRUE)
  
  expect_equal(predictCox(fit.coxph, keep.strata = TRUE)$strata, 
               basehaz(fit.coxph)$strata)
  expect_equal(predictCox(fit.cph, keep.strata = TRUE)$strata, 
               basehaz(fit.cph)$strata)
  # expect_equal(as.numeric(predictCox(fit.coxph, keep.strata = TRUE)$strata), 
  #              as.numeric(predictCox(fit.cph, keep.strata = TRUE)$strata))
})

test_that("baseline hazard (strata) - match basehaz results",{
  fit.coxph <- coxph(Surv(time,status == 1) ~ thick + strata(invasion) + strata(ici), data = Melanoma, y = TRUE, x = TRUE)
  fit.cph <- cph(Surv(time,status == 1) ~ thick + strat(invasion) + strat(ici), data = Melanoma, y = TRUE, x = TRUE)
  
  expect_equal(predictCox(fit.coxph, centered = FALSE)$cumhazard, 
               basehaz(fit.coxph, centered = FALSE)$hazard, tolerance = 1e-8)
  expect_equal(predictCox(fit.cph)$cumhazard, 
               basehaz(fit.cph)$hazard)
  
  ## !!! not the same ordering in the strata between cph and coxph thus the results in predictCox differ in order
  ## possible differences due to different fit - coef(fit.coxph)-coef(fit.cph)
  # expect_equal(basehaz(fit.coxph)$hazard[predictCox(fit.cph)$hazard>0], 
  #              basehaz(fit.cph)$hazard)
  # expect_equal(predictCox(fit.cph, centered = TRUE),
  #              predictCox(fit.coxph, centered = TRUE), 
  #              tolerance = 100*max(abs(coef(fit.coxph)-coef(fit.cph))))
})

# }}}

# {{{ 6- [predictCox] Check format of the output
cat("Format of the output \n")
data(Melanoma)
times1 <- unique(Melanoma$time)
times2 <- c(0,0.9*min(times1),times1*1.1)
dataset1 <- Melanoma[sample.int(n = nrow(Melanoma), size = 12),]

## no strata
fit.coxph <- coxph(Surv(time,status == 1) ~ thick*age, data = Melanoma, y = TRUE, x = TRUE)
fit.cph <- cph(Surv(time,status == 1) ~ thick*age, data = Melanoma, y = TRUE, x = TRUE)

test_that("baseline hazard - correct number of events",{
    # c("time","hazard","cumhazard","survival") remove lastEventTime from pfit
    # time hazard cumhazard survival should have length equals to the number of eventtimes (including censored events)
    # this is not true for lastEventTime which is has length the number of strata
    pfit.coxph <- predictCox(fit.coxph, type = c("hazard","cumhazard","survival"), keep.times = TRUE)[c("time","hazard","cumhazard","survival")]
    lengthRes <- unlist(lapply(pfit.coxph, length))
    expect_equal(unname(lengthRes), rep(length(unique(fit.coxph$y[,"time"])), 4))
    pfit.cph <- predictCox(fit.cph, type = c("hazard","cumhazard","survival"), keep.times = TRUE)[c("time","hazard","cumhazard","survival")]
    lengthRes <- unlist(lapply(pfit.cph, length))
    expect_equal(unname(lengthRes), rep(length(unique(fit.cph$y[,"time"])), 4))
})

## strata
fit.coxph <- coxph(Surv(time,status == 1) ~ thick + strata(invasion) + strata(ici), data = Melanoma, y = TRUE, x = TRUE)
fit.cph <- cph(Surv(time,status == 1) ~ thick + strat(invasion) + strat(ici), data = Melanoma, y = TRUE, x = TRUE)

test_that("baseline hazard (strata) - order of the results",{
  expect_equal(as.numeric(predictCox(fit.coxph, keep.strata = TRUE)$strata),
               as.numeric(basehaz(fit.coxph)$strata))
  expect_equal(as.numeric(predictCox(fit.cph, keep.strata = TRUE)$strata),
               as.numeric(basehaz(fit.cph)$strata))
})

test_that("baseline hazard (strata) - correct number of events",{
    # c("time","hazard","cumhazard","survival", "strata") remove lastEventTime from pfit
    # time hazard cumhazard survival and strata should have length equals to the number of eventtimes (including censored events)
    # this is not true for lastEventTime which is has length the number of strata

  strata <- interaction(Melanoma$invasion, Melanoma$ici)
  timePerStrata <- tapply(fit.coxph$y[,"time"],strata, function(x){length(unique(x))})

  pfit.coxph <- predictCox(fit.coxph, type = c("hazard","cumhazard","survival"), keep.times = TRUE, keep.strata = TRUE)[c("time","hazard","cumhazard","survival","strata")]
  lengthRes <- unlist(lapply(pfit.coxph, length))
  expect_equal(unname(lengthRes), rep(sum(timePerStrata), 5))
  pfit.cph <- predictCox(fit.cph, type = c("hazard","cumhazard","survival"), keep.times = TRUE, keep.strata = TRUE)[c("time","hazard","cumhazard","survival","strata")]
  lengthRes <- unlist(lapply(pfit.cph, length))
  expect_equal(unname(lengthRes), rep(sum(timePerStrata), 5))
})



test_that("Prediction with Cox model (strata) - export of strata and times",{
    fit.coxph <- coxph(Surv(time,status == 1) ~ thick + strata(invasion) + strata(ici), data = Melanoma, y = TRUE, x = TRUE)
    fit.cph <- cph(Surv(time,status == 1) ~ thick + strat(invasion) + strat(ici), data = Melanoma, y = TRUE, x = TRUE)
    predictTempo <- predictCox(fit.coxph)
    expect_equal(length(predictTempo$strata)>0, TRUE) 
    expect_equal(length(predictTempo$time)>0, TRUE)
    predictTempo <- predictCox(fit.coxph, keep.strata = FALSE) # as.data.table(predictCox(fit.coxph, keep.strata = TRUE))
    expect_equal(length(predictTempo$strata)>0, FALSE) 
    expect_equal(length(predictTempo$time)>0, TRUE)
    predictTempo <- predictCox(fit.coxph, keep.strata = FALSE, keep.times = FALSE)
    expect_equal(length(predictTempo$strata)>0, FALSE)
    expect_equal(length(predictTempo$time)>0, FALSE)
  
  predictTempo <- predictCox(fit.coxph, times = sort(times2), newdata = dataset1)
  expect_equal(length(predictTempo$strata)>0, TRUE) 
  expect_equal(length(predictTempo$time)>0, TRUE)
  predictTempo <- predictCox(fit.coxph, times = sort(times2), newdata = dataset1, keep.strata = FALSE)
  expect_equal(length(predictTempo$strata)>0, FALSE)
  expect_equal(length(predictTempo$time)>0, TRUE)
  predictTempo <- predictCox(fit.coxph, times = sort(times2), newdata = dataset1, keep.strata = FALSE, keep.times = FALSE)
  expect_equal(length(predictTempo$strata)>0, FALSE)
  expect_equal(length(predictTempo$time)>0, FALSE)
})

test_that("Prediction with Cox model (strata) - consistency of hazard/cumhazard/survival",{
  predictTempo <- predictCox(fit.coxph, type = c("hazard","cumhazard","survival"), times = times1, newdata = dataset1)
  expect_equal(predictTempo$hazard[,-1], t(apply(predictTempo$cumhazard,1,diff)), tolerance = 1e-8)
  expect_equal(predictTempo$survival, exp(-predictTempo$cumhazard), tolerance = 1e-8)
})

predictTempo <- predictCox(fit.coxph, type = c("hazard","cumhazard","survival"), times = c(0,times1[1:10]), newdata = dataset1[1:2,])
expect_equal(predictTempo$hazard[,-1], t(apply(predictTempo$cumhazard,1,diff)), tolerance = 1e-8)
expect_equal(predictTempo$survival, exp(-predictTempo$cumhazard), tolerance = 1e-8)


test_that("Prediction with Cox model (strata) - incorrect strata",{
    fit.coxph <- coxph(Surv(time,status == 1) ~ thick + strata(invasion) + strata(ici), data = Melanoma, y = TRUE, x = TRUE)
    dataset1$invasion <- "5616"
    expect_error(predictCox(fit.coxph, times = times1, newdata = dataset1))
})
# }}}

# {{{ 7- Conditional CIF 
cat("Conditional CIF \n")

set.seed(10)
d <- SimCompRisk(1e2)
d$time <- round(d$time,1)
ttt <- sample(x = unique(sort(d$time)), size = 10)
d2 <- SimCompRisk(1e2)

#### coxph function
CSC.fit <- CSC(Hist(time,event)~ X1+X2,data=d, method = "breslow")

test_that("Conditional CIF identical to CIF before first event", {
  pred <- predict(CSC.fit, newdata = d, cause = 2, times = ttt)
  predC <- predict(CSC.fit, newdata = d, cause = 2, times = ttt, landmark = min(d$time)-1e-5)
  expect_equal(pred, predC)

  pred <- predict(CSC.fit, newdata = d2, cause = 2, times = ttt)
  predC <- predict(CSC.fit, newdata = d2, cause = 2, times = ttt, landmark = min(d$time)-1e-5)
  expect_equal(pred, predC)
})

test_that("Conditional CIF is NA after the last event", {
  predC <- predict(CSC.fit, newdata = d, cause = 2, times = ttt, landmark = max(d$time)+1)
  expect_equal(all(is.na(predC$absRisk)), TRUE)
  
  predC <- predict(CSC.fit, newdata = d2, cause = 2, times = ttt, landmark = max(d$time)+1)
  expect_equal(all(is.na(predC$absRisk)), TRUE)
  
  t0 <- mean(range(d$time))
  ttt0 <- c(t0,ttt)
  predC <- predict(CSC.fit, newdata = d, cause = 2, times = ttt0, landmark = t0)
  expect_equal(all(is.na(predC$absRisk[,ttt0<t0])), TRUE)
  expect_equal(all(!is.na(predC$absRisk[,ttt0>=t0])), TRUE)
})

test_that("Value of the conditional CIF | at the last event", {
    tau <-  max(d[cause==2,time])
    
    predC_auto <- predict(CSC.fit, newdata = d2[1:5], cause = 2, times = tau, landmark = tau, productLimit = FALSE)
    pred <- as.data.table(predictCox(CSC.fit$models[[2]], times = tau, newdata = d2[1:5], type = "hazard"))
    expect_equal(as.double(predC_auto$absRisk),pred$hazard)

    predC_auto <- predict(CSC.fit, newdata = d2[1:5], cause = 2, times = tau, landmark = tau, productLimit = TRUE)
    pred <- as.data.table(predictCox(CSC.fit$models[[2]], times = tau, newdata = d2[1:5], type = "hazard"))
    expect_equal(as.double(predC_auto$absRisk),pred$hazard)
})

test_that("Value of the conditional CIF", {
  sttt <- sort(c(0,ttt))
  indexT0 <- 5
    
  # productLimit = FALSE
  cumH1 <- predictCox(CSC.fit$models$`Cause 1`, newdata = d2, times = sttt[indexT0]-1e-6)[["cumhazard"]]
  cumH2 <- predictCox(CSC.fit$models$`Cause 2`, newdata = d2, times = sttt[indexT0]-1e-6)[["cumhazard"]]
  Sall <- exp(-cumH1-cumH2)
  
  predRef <- predict(CSC.fit, newdata = d2, cause = 2, times = sttt[indexT0]-1e-6, productLimit = FALSE)
  
  pred <- predict(CSC.fit, newdata = d2, cause = 2, times = sttt, productLimit = FALSE)
  predC_manuel <- (pred$absRisk-as.double(predRef$absRisk))/as.double(Sall)
  predC_manuel[,seq(1,indexT0-1)] <- NA
  
  predC_auto <- predict(CSC.fit, newdata = d2, cause = 2, times = sttt, landmark = sttt[indexT0], productLimit = FALSE)
  expect_equal(predC_auto$absRisk,predC_manuel)
  # predC_auto$absRisk - predC_manuel

  # productLimit = TRUE
  h1 <- predictCox(CSC.fit$models$`Cause 1`, newdata = d2, times = CSC.fit$eventTimes, type = "hazard")[["hazard"]]
  h2 <- predictCox(CSC.fit$models$`Cause 2`, newdata = d2, times = CSC.fit$eventTimes, type = "hazard")[["hazard"]]
  Sall <- apply(1-h1-h2,1, function(x){
      c(1,cumprod(x))[sindex(jump.times = CSC.fit$eventTimes, eval.times = sttt[indexT0]-1e-6)+1]
  })
  predRef <- predict(CSC.fit, newdata = d2, cause = 2, times = sttt[indexT0]-1e-6, productLimit = TRUE)
  
  pred <- predict(CSC.fit, newdata = d2, cause = 2, times = sttt, productLimit = TRUE)
  predC_manuel <- sweep(pred$absRisk-as.double(predRef$absRisk), MARGIN = 1, FUN ="/", STATS = as.double(Sall))
  predC_manuel[,seq(1,indexT0-1)] <- NA
  
  predC_auto <- predict(CSC.fit, newdata = d2, cause = 2, times = sttt, landmark = sttt[indexT0], productLimit = TRUE)
  expect_equal(predC_auto$absRisk,predC_manuel)
  # predC_auto$absRisk-predC_manuel
})
# }}}

# {{{ 8 - Delayed entry 
cat("Delayed entry \n")
d <- SimSurv(1e2)
d$entry <- d$eventtime - abs(rnorm(NROW(d)))

m.cox <- coxph(Surv(entry,eventtime,status)~X1+X2,data=d, x = TRUE)
test_that("Prediction with Cox model - delayed entry",{
  expect_error(predictCox(m.cox))
})
# }}}

# {{{ 10 - Strata
cat("strata \n")
# check previous issue with strata
f1 <- coxph(Surv(time,status==1) ~ age+logthick+epicel+strata(sex),data=Melanoma,
            x=TRUE,y=TRUE)
res <- predictCox(f1,newdata=Melanoma[c(17,101,123),],
                  times=c(7,3,5)*365.25)
# }}}

# {{{ 11- [predictRisk] Others
cat("Others \n")

set.seed(10)
n <- 300
df.S <- SimCompRisk(n)
df.S$time <- round(df.S$time,2)
df.S$X3 <- rbinom(n, size = 4, prob = rep(0.25,4))
method.ties <- "efron"
cause <- 1

n <- 3
set.seed(3)
dn <- SimCompRisk(n)
dn$time <- round(dn$time,2)
dn$X3 <- rbinom(n, size = 4, prob = rep(0.25,4))
CSC.h3 <- CSC(Hist(time,event) ~ X1 + strat(X3) + X2, data = df.S, ties = method.ties, fitter = "cph")
CSC.h1 <- CSC(Hist(time,event) ~ strat(X1) + X3 + X2, data = df.S, ties = method.ties, fitter = "cph")
CSC.h <- CSC(Hist(time,event) ~ strat(X1) + strat(X3) + X2, data = df.S, ties = method.ties, fitter = "cph")
CSC.s <- CSC(Hist(time,event) ~ strata(X1) + strata(X3) + X2, data = df.S, ties = method.ties, fitter = "coxph")
predictRisk(CSC.h1, newdata = dn, times = c(5,10,15,20), cause = cause)
predictRisk(CSC.h3, newdata = dn, times = c(5,10,15,20), cause = cause)

CSC.h0 <- CSC(Hist(time,event) ~ X1 + X3 + X2, data = df.S, ties = method.ties, fitter = "cph")
predictRisk(CSC.h0, newdata = dn, times = c(5,10,15,20), cause = cause)

predictRisk(CSC.h1, newdata = dn, times = c(5,10,15,20), cause = cause)
predictRisk(CSC.s, newdata = dn, times = c(5,10,15,20), cause = cause)


df.S[df.S$time==6.55,c("time","event")]
predictCox(CSC.h$models[[1]],newdata = dn[1,],times=c(2.29,6.55),type="hazard")
predictCox(CSC.h$models[[2]],newdata = dn[1,],times=6.55,type="hazard")

predictCox(CSC.h$models[["Cause 1"]],newdata = dn[1,],times=CSC.h$eventTimes,type="hazard")$hazard

test_that("Prediction with CSC - categorical cause",{
predictRisk(CSC.h, newdata = dn[1,], times = c(2), cause = "1")
})

predictRisk(CSC.h, newdata = dn, times = c(1,2,3.24,3.25,3.26,5,10,15,20), cause = cause)
predictRisk(CSC.s, newdata = dn, times = c(1,5,10,15,20), cause = cause)

predictCox(CSC.s$models[[1]], newdata = dn, times = c(5,10,15,20))

predictRisk(CSC.h$models[[1]], newdata = dn, times = c(5,10,15,20), cause = cause)
predictRisk(CSC.s$models[[1]], newdata = dn, times = c(5,10,15,20), cause = cause)

predictRisk(CSC.h$models[[2]], newdata = dn, times = c(5,10,15,20), cause = cause)
predictRisk(CSC.s$models[[2]], newdata = dn, times = c(5,10,15,20), cause = cause)
# }}}

#----------------------------------------------------------------------
### predictRisk.R ends here
