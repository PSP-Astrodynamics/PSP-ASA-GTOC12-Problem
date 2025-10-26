%% SVC METAMODELING: BREAST CANCER DIAGNOSIS DATA SET
%
% This example showcases how to perform Support Vector Machine
% for Classification (SVC) metamodeling
% on the Wisconsin breast cancer diagnostic data set.
%
% For more information, see:
% Street, W. N., W. H. Wolberg, and O. L. Mangasarian. (1993).
% Nuclear feature extraction for breast tumor diagnosis.
% IS&T/SPIE 1993 International Symposium on Electronic Imaging: 
% Science and Technology, 861-870.
% <https://doi.org/10.1117/12.148698 DOI:10.1117/12.148698>

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace,
% set the random number generator for reproducible results,
% and initialize the UQLab framework:
clearvars
rng(1,'twister')
uqlab

%% 2 - RETRIEVE DATA SET
%
% The data set is stored in a MAT-file located in:
FILELOCATION = fullfile(...
    uq_rootPath, 'Examples', 'SimpleDataSets', 'Breast_Cancer');

%%
% Read the data set file and store the contents in matrices:
load(fullfile(FILELOCATION,'wdbc.mat'), 'X', 'Y');

%% 3 - TRAINING AND VALIDATION SETS
%
% Use $70\%$ of the data set for training and the rest for validation:
Ntrain = floor(0.7*size(X,1));

%%
% Get the indices of the training (resp. validation) sample:
idx_train = randperm(size(X,1), Ntrain);
Xtrain = X(idx_train,:);
Ytrain = Y(idx_train,:);

idx_val = setdiff(1:size(X,1),idx_train); 
Xval = X(idx_val,:);
Yval = Y(idx_val,:);

%% 4 - SVC METAMODEL
%
% Select SVC as the metamodeling tool:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'SVC';

%% 
% Use the data set loaded earlier:
MetaOpts.ExpDesign.X = Xtrain;
MetaOpts.ExpDesign.Y = Ytrain;

%%
% Use linear penalization:
MetaOpts.Penalization = 'linear';

%%
% Use the Sequential Minimal Optimization (SMO) algorithm to solve the
% quadratic programming problem:
MetaOpts.QPSolver = 'SMO';

%%
% Use the Gaussian kernel:
MetaOpts.Kernel.Family = 'Gaussian';

%%
% Use the span leave-one-out (LOO) estimate
% to calibrate the hyperparameters:
MetaOpts.EstimMethod = 'CV';

%%
% Use grid search-based hyperparameter optimization:
MetaOpts.Optim.Method = 'GS';

%%
% Provide the validation data set to get the validation error:
MetaOpts.ValidationSet.X = Xval;
MetaOpts.ValidationSet.Y = Yval;

%%
% Create the SVC metamodel:
mySVC = uq_createModel(MetaOpts);

%% 5 - PERFORMANCE EVALUATION
%
% Evaluate the SVC metamodel at the validation set points:
Yhat = uq_evalModel(mySVC,Xval);

%%
% Compute the percentage of the SVC metamodel accuracy:
accSVC = sum(Yhat == Yval)*100 /length(Yval)

%%
% Compute the percentage of false positives:
falsePosSVC = sum(Yhat == 1 & Yval == -1)*100/sum(Yval == -1)

%%
% Compute the percentage of false negatives:
falseNegSVC = sum(Yhat == -1 & Yval == 1)*100/sum(Yval == 1)

%% 6 - APPLICATION OF SVC PROBABILITY OUTPUT
%
% It is desirable for a health diagnosis predictor to have a minimal
% number of false negatives.
% One way to improve the predictor is by using the probabilistic 
% estimates of Y for each X:
[~,probYhat_val] = uq_evalModel(mySVC,Xval);

%%
% By default, negative (resp. positive) values are classified as -1
% (resp. 1). Here a different cut-off value selected: 
cutoff = -0.4;

%%
% Compute new predictions based on the probabilistic estimates
% and the cut-off value set above:
Yhat2 = zeros(size(probYhat_val));
Yhat2(probYhat_val < cutoff) = -1;
Yhat2(probYhat_val >= cutoff) = 1;

%%
% Compute the percentage of the new predictions accuracy:
accSVC2 = sum(Yhat2 == Yval)*100 /length(Yval)

%%
% Compute the percentage of false positives:
falsePosSVC2 = sum(Yhat2 == 1 & Yval == -1)*100/sum(Yval == -1)

%%
% Compute the percentage of false negatives:
falseNegSVC2 = sum(Yhat2 == -1 & Yval == 1)*100/sum(Yval == 1)

%%
% There is a trade-off between the false negatives 
% and the overall accuracy of the SVC metamodel
% with varying cut-off values.

%%
% Compute the accuracy, false negative, and false positive
% for different values of cut-off values:
cutOffVals = linspace(-1.5,1.5,10);
accVals = zeros(size(cutOffVals));
falsePosVals = zeros(size(cutOffVals));
falseNegVals = zeros(size(cutOffVals));
YhatCurr = zeros(size(probYhat_val));

for ii = 1:length(cutOffVals)
    YhatCurr(probYhat_val < cutOffVals(ii)) = -1;
    YhatCurr(probYhat_val >= cutOffVals(ii)) = 1;
    accVals(ii) = sum(YhatCurr == Yval)*100 /length(Yval);
    falseNegVals(ii) = sum(YhatCurr == -1 & Yval == 1)*100/sum(Yval == 1);
    falsePosVals(ii) = sum(YhatCurr == 1 & Yval == -1)*100/sum(Yval == -1);
end

%%
% Create a plot illustrating the trade-off:
uq_figure
uq_plot(...
    cutOffVals, accVals,...
    cutOffVals, falsePosVals,...
    cutOffVals, falseNegVals)
uq_legend(...
    {'Accuracy', 'False positives', 'False negatives'},...
    'Location', 'east')
xlabel('Cut-off value')
ylabel('\%')
