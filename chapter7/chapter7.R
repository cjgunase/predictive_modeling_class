############## chapter 7 ##############

## We will use packeges: caret, earth, kernlab, and nnet
install.packages(c("caret", "earth", "kernlab", "nnet"))

## nnet package can be used to creat neural networks

library(nnet)

#### Neural Networks #########

## nnet function takes both the formula and nonformula interfaces
## For regression, the linear relationship between the hidden
## units and the prediction can be used with the option linout = TRUE

## A basic neural network function call would be

nnetFit <- nnet(predictors, outcome,
                size = 5,
                decay = 0.01,
                linout = TRUE,
                ## Reduce the amount of printed output
                trace = FALSE,
                ## Expand the number of iterations to find
                ## parameter estimates..
                maxit = 500,
                ## and the number of parameters used by the model
                MaxNWts = 5 * (ncol(predictors) + 1) + 5 + 1)

## This would create a single model with 5 hidden units. 
## The data in predictors should be standardized to be on the same scale.

## To use model averaging, the avNNet function in the caret package 
## has nearly identical syntax:

nnetAvg <- avNNet(predictors, outcome,
                  size = 5,
                  decay = 0.01,
                  ## Specify how many models to average
                  repeats = 5,
                  linout = TRUE,
                  ## Reduce the amount of printed output
                  trace = FALSE,
                  ## Expand the number of iterations to find
                  ## parameter estimates..
                  maxit = 500,
                  ## and the number of parameters used by the model
                  MaxNWts = 5 * (ncol(predictors) + 1) + 5 + 1)

## new samples are processed using

predict(nnetFit, newData)
## or
predict(nnetAvg, newData)

## to choose the number of hidden units and
## the amount of weight decay via resampling, 
## the train function can be applied
## using either method = "nnet" or method = "avNNet".

## first, remove predictors to ensure that the maximum
## absolute pairwise correlation between the
## predictors is less than 0.75

## The findCorrelation takes a correlation matrix and determines the
## column numbers that should be removed to keep all pair-wise
## correlations below a threshold

tooHigh <- findCorrelation(cor(solTrainXtrans), cutoff = .75)
trainXnnet <- solTrainXtrans[, -tooHigh]
testXnnet <- solTestXtrans[, -tooHigh]

## Create a specific candidate set of models to evaluate:

nnetGrid <- expand.grid(.decay = c(0, 0.01, .1),
                        .size = c(1:10),
                        ## The next option is to use bagging (see the
                        ## next chapter) instead of different random
                        ## seeds.
                        .bag = FALSE)
set.seed(100)
nnetTune <- train(solTrainXtrans, solTrainY,
                  method = "avNNet",
                  tuneGrid = nnetGrid,
                  trControl = ctrl,
                  ## Automatically standardize data prior to modeling
                  ## and prediction
                  preProc = c("center", "scale"),
                  linout = TRUE,
                  trace = FALSE,
                  MaxNWts = 10 * (ncol(trainXnnet) + 1) + 10 + 1,
                  maxit = 500)

############ Multivariate Adaptive Regression Splines ############
## MARS models are in the earth package. 
## The MARS model using the nominal forward pass
## and pruning step can be called simply

marsFit <- earth(solTrainXtrans, solTrainY)
marsFit

Note that since this model used the internal GCV technique for model selection,
the details of this model are different than the one used previously in
the chapter. The summary method generates more extensive output:
> summary(marsFit)

## The summary method generates more extensive output:
summary(marsFit)

## In this output, h(�) is the hinge function.
## The plotmo function in the earth package can be used to produce plots
## similar to Fig. 7.5. 
## To tune the model using external resampling, the train
## function can be used. The following code reproduces the results in Fig. 7.4:
# Define the candidate models to test
marsGrid <- expand.grid(.degree = 1:2, .nprune = 2:38)
# Fix the seed so that the results can be reproduced
set.seed(100)
marsTuned <- train(solTrainXtrans, solTrainY,
                   method = "earth",
                   # Explicitly declare the candidate models to test
                   tuneGrid = marsGrid,
                   trControl = trainControl(method = "cv"))
marsTuned
head(predict(marsTuned, solTestXtrans))

## There are two functions that estimate the importance of each predictor 
## in the MARS model: evimp in the earth package and varImp in the caret package

varImp(marsTuned)

############## Support Vector Machines ############

## A more comprehensive implementation of SVM models for regression 
## is the kernlab package. The ksvm function is available for
## regression models and a large number of kernel functions. 
## The radial basis function is the default kernel function. 
## If appropriate values of the cost and kernel parameters are known, 
## this model can be fit as

svmFit <- ksvm(x = solTrainXtrans, y = solTrainY,
               kernel ="rbfdot", kpar = "automatic",
               C = 1, epsilon = 0.1)
## The function automatically uses the analytical approach to estimate s.

## If the values are unknown, they can be estimated through resampling. 
## In train, the method values of "svmRadial", "svmLinear", or "svmPoly" 
## fit different kernels:
svmRTuned <- train(solTrainXtrans, solTrainY,
                   method = "svmRadial",
                   preProc = c("center", "scale"),
                   tuneLength = 14,
                   trControl = trainControl(method = "cv"))

## The tuneLength argument will use the default grid search of 14 cost values
## between 2-2, 2-1, . . . , 211. s is estimated analytically by default.
svmRTuned

## The subobject named finalModel contains the model created by the ksvm
## function:

svmRTuned$finalModel

## we see that the model used 625 training set data points as support
## vectors (66% of the training set).

############## K-Nearest Neighbors ###############

## The knnreg function in the caret package fits the KNN regression model; 
## train tunes the model over K:
# Remove a few sparse and unbalanced fingerprints first
knnDescr <- solTrainXtrans[, -nearZeroVar(solTrainXtrans)]
set.seed(100)
knnTune <- train(knnDescr,
                 solTrainY,
                 method = "knn",
                 # Center and scaling will occur for new predictions too
                 preProc = c("center", "scale"),
                 tuneGrid = data.frame(.k = 1:20),
                 trControl = trainControl(method = "cv"))

## When predicting new samples using this object, the new samples are 
## automatically centered and scaled using the values determined 
## cby the training set.













































