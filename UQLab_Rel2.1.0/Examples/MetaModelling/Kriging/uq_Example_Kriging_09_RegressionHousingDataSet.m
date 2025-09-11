%% KRIGING METAMODELING: REGRESSION MODEL FOR HOUSING DATA SET
%
% This example showcases how to perform Gaussian process regression
% modeling in the Kriging module using existing data sets.
% The example revisits |uq_Example_Kriging_06_HousingDataSet| and compares
% both interpolation and regression models.
%
% For more information, see:
% Harrison, D., Jr. and D. L. Rubinfeld (1978).
% Hedonic prices and the demand for clean air.
% Journal of Environmental Economics and Management, 5(1), 81-102.
% <https://doi.org/10.1016/0095-0696(78)90006-2 DOI:10.1016/0095-0696(78)90006-2>

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(1,'twister')
uqlab

%% 2 - RETRIEVE DATA SET
%
% The housing data set is stored in a MAT-file in the following location:
FILELOCATION = fullfile(...
    uq_rootPath, 'Examples', 'SimpleDataSets', 'Boston_Housing');

%%
% Read the data set and store the contents in matrices:
load(fullfile(FILELOCATION,'housing.mat'), 'X', 'Y')

%%
% Get the size of the experimental design:
[N,M] = size(X);

%% 3 - TRAINING AND VALIDATION SETS
%
% Use $80\%$ of the data for training and the rest for validation:
Ntrain = floor(0.8*N);
Nval = N - Ntrain;

%% 4 - KRIGING METAMODELS
%
% Kriging metamodels are created using different replications of the
% housing data set.
% In each replication, a training set of size |Ntrain| is randomly sampled
% from the whole housing data set.
% The size of the training set in each replication is the same.
% Specifically, the steps are as follows:
%
% # Randomly split the available data into a traning and a validation sets
% # Define and create a Kriging metamodel based on the training set
% # Evaluate the Kriging metamodel at the validation set points
%
% Both Kriging interpolation and regression models are created
% and later on compared.

%%
% First, initialize the results matrices:
Nreps = 5;                       % Number of repetitions
XtrainIdx = zeros(Ntrain,Nreps); % Indices for training data
XvalidIdx = zeros(Nval,Nreps);   % Indices for validation data
Yvalid = zeros(Nval,Nreps);      % Validation set, responses
YKrgInt = zeros(Nval,Nreps);     % Prediction on validation set, interp.
YKrgReg = zeros(Nval,Nreps);     % Prediction on validation set, regression
valError = zeros(Nreps,2);       % Validation errors
iterTxt = cell(Nreps,1);         % text for legend

%% 4.1 Interpolation model
%
% An interpolation model for each replication is created as follows:
for iter = 1:Nreps
    % Randomly split the data into a training and a validation set 
    idxTrain = randperm(N,Ntrain)';
    XtrainIdx(:,iter) = idxTrain;
    idxValid = setdiff(1:N,idxTrain);
    XvalidIdx(:,iter) = idxValid;
    Xtrain = X(idxTrain,:);         % Training data, input
    Ytrain = Y(idxTrain);           % Training data, output
    Xvalid = X(idxValid,:);         % Validation data, input
    Yvalid(:,iter) = Y(idxValid);   % Validation data, output
    
    % Select Kriging as the metamodeling tool
    MetaOpts.Type = 'Metamodel';
    MetaOpts.MetaType = 'Kriging';

    % Use a linear trend for the Kriging metamodel
    MetaOpts.Trend.Type = 'linear';

    % Use the CMAES optimization algorithm to calibrate the hyperparameters
    MetaOpts.Optim.Method = 'CMAES';

    % Assign the training data set as the experimental design
    MetaOpts.ExpDesign.X = Xtrain;
    MetaOpts.ExpDesign.Y = Ytrain;
    
    % Assign the validation data set
    MetaOpts.ValidationSet.X = Xvalid;
    MetaOpts.ValidationSet.Y = Yvalid(:,iter);

    % Create the metamodel object and add it to UQLab
    myKriging = uq_createModel(MetaOpts);
    
    % Evaluate the Kriging metamodel at the validation set points
    YKrgInt(:,iter) = uq_evalModel(myKriging,Xvalid);
    
    % Store the validation error of each replication
    valError(iter,1) = myKriging.Error.Val;
    
    % Create a Legend entry
    iterTxt{iter} = sprintf('Replication %i', iter);
end

%% 4.2 Regression model
%
% The steps above are now repeated with noise estimation option activated
% to create a regression model (all other options are kept the same):
for iter = 1:Nreps
    % Randomly split the data into a training and a validation sets
    idxValid = XvalidIdx(:,iter);
    idxTrain = XtrainIdx(:,iter);
    Xtrain = X(idxTrain,:);
    Ytrain = Y(idxTrain);
    Xvalid = X(idxValid,:);

    % Activate the noise estimation option
    MetaOpts.Regression.SigmaNSQ = 'auto';

    % Assign the training data set as the experimental design
    MetaOpts.ExpDesign.X = Xtrain;
    MetaOpts.ExpDesign.Y = Ytrain;
    
    % Assign the validation data set
    MetaOpts.ValidationSet.X = Xvalid;
    MetaOpts.ValidationSet.Y = Yvalid(:,iter);

    % Create the metamodel object and add it to UQLab
    myKriging = uq_createModel(MetaOpts);
    
    % Evaluate the Kriging metamodel at the validation set points
    YKrgReg(:,iter) = uq_evalModel(myKriging,Xvalid);
    
    % Store the validation error of each replication
    valError(iter,2) = myKriging.Error.Val;
end

%% 5 - VALIDATION
% 
% Compare the predictions of both models at the validation set points
% against the true values over the $5$ replications:

% Plot the interpolation model results
uq_figure

uq_plot(Yvalid, YKrgInt, '+')
hold on
uq_plot([0 60], [0 60], 'k')
hold off
axis equal
axis([0 60 0 60])
title('Interpolation model')
xlabel('$\mathrm{Y_{true}}$')
ylabel('$\mathrm{Y_{Kriging}}$')
uq_legend(iterTxt, 'Location', 'southeast')

% Plot the regression model results
uq_figure
uq_plot(Yvalid, YKrgReg, '+')
hold on
uq_plot([0 60], [0 60], 'k')
hold off
title('Regression model')
xlabel('$\mathrm{Y_{true}}$')
ylabel('$\mathrm{Y_{Kriging}}$')
axis equal
axis([0 60 0 60])
uq_legend(iterTxt, 'Location', 'southeast')

%%
% The validation error of each replication can also be printed out for
% comparison:
uq_printMatrix(valError, iterTxt, {'interpolation', 'regression'})

%%
% In this particular example, due to the noise in the dataset,
% the Kriging regression model performs better on the validation set
% than the classical Kriging (i.e., interpolation) model.
