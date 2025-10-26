%% KRIGING METAMODELING: HOUSING DATA SET
%
% This example showcases how to perform Kriging metamodeling using existing
% data sets.
% A standard machine learning data set related to the housing prices
% in Boston is considered.
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

%% 2 - RETRIEVE DATA SETS
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

%%
% Initialize the results matrices:
Nreps = 5;
Yval = zeros(Nval,Nreps);
YKrg = zeros(Nval,Nreps);
legendText = cell(Nreps,1);

%% 4 - KRIGING METAMODELS
%
% Five Kriging metamodels are created using different
% training sets of the same size (|Ntrain|) randomly sampled
% from the whole housing data set.
% The steps (repeated five times) are as follows:
%
% # Randomly split the available data into a traning and a validation sets
% # Define and create a Kriging metamodel based on the training set
% # Evaluate the Kriging metamodel at the validation set points
%
for iter = 1:Nreps
    % Randomly split the data into a training and a validation sets 
    idx_train = randperm(N,Ntrain);
    idx_val = setdiff(1:N,idx_train);
    Xtrain = X(idx_train,:);
    Ytrain = Y(idx_train);
    Xval = X(idx_val,:);
    Yval(:,iter) = Y(idx_val);
    
    % Select Kriging as the metamodeling tool
    MetaOpts.Type = 'Metamodel';
    MetaOpts.MetaType = 'Kriging';

    % Use a linear trend for the Kriging metamodel
    MetaOpts.Trend.Type = 'linear';

    % Use the CMAES optimization algorithm to estimate the hyperparameters
    MetaOpts.Optim.Method = 'CMAES';

    % Assign the training data set as the experimental design
    MetaOpts.ExpDesign.X = Xtrain;
    MetaOpts.ExpDesign.Y = Ytrain;

    % Create the metamodel object and add it to UQLab
    myKriging = uq_createModel(MetaOpts);
    
    % Evaluate the Kriging metamodel at the validation set points
    YKrg(:,iter) = uq_evalModel(myKriging,Xval);
    
    % Create a text for legend
    legendText{iter} = sprintf('Iteration %i', iter);
end

%% 5 - VALIDATION
% 
% Compare the Kriging predictions at the validation set points
% against the true values over the $5$ repetitions:
uq_figure

uq_plot(Yval, YKrg, '+')
hold on
uq_plot([0 60], [0 60], 'k')
hold off

axis equal
axis([0 60 0 60])

uq_legend(legendText, 'Location', 'southeast')

xlabel('$\mathrm{Y_{true}}$')
ylabel('$\mathrm{Y_{Krg}}$')
