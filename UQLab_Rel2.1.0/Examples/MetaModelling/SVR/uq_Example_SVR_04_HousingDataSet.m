%% SVR METAMODELING: BOSTON HOUSING DATA SET
%
% This example showcases how to use Support Vector Machine for Regression
% (SVR) metamodeling on existing data sets.
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
rng(100,'twister')
uqlab

%%
% This example uses, by default, the sequential minimal optimization (SMO)
% quadratic programming (QP) optimizer.
% This feature is available in the Matlab Statistics and Machine Learning
% Toolbox R2015b or above.
% Therefore, its availability is first checked;
% if it is not available, then issue a warning
% and revert to the interior point (IP) algorithm:
QPSolver = 'SMO';
if ~exist('fitrsvm','file')
    warning(['SMO is not available on this version of Matlab. ',...
        'Setting QP Solver to IP'])
    % IP with a large training set may be slow to converge
    fprintf('This example may take some time!')
    QPSolver = 'IP';
end

%% 2 - RETRIEVE DATA SETS
%
% The housing data set is stored in a MAT-file in the following location:
FILELOCATION = fullfile(...
    uq_rootPath, 'Examples', 'SimpleDataSets', 'Boston_Housing');

%%
% Read the data set and store the content in matrices:
load(fullfile(FILELOCATION,'housing.mat'), 'X', 'Y')

%% 3 - TRAINING AND VALIDATION SETS
%
% Retrieve the size of the experimental design:
[N,M] = size(X);

%%
% Use $85\%$ of the data for training and the rest for validation:
Ntrain = floor(0.85*N);
Nval = N - Ntrain;

%% 4 - SVR METAMODELS
%
% Three SVR metamodels are created using different training sets of the
% same size (|Ntrain|) randomly sampled from the whole housing data set.
% The steps (repeated three times) are as follows:
%
% # Randomly split the available data into a traning and a validation sets
% # Define and create a SVR metamodel based on the training set
% # Evaluate the SVR metamodel at the validation set points

%%
% Initialize the results matrices:
Nreps = 3;                   % Number of repetitions
Yval = zeros(Nval,Nreps);    % Validation set, responses
YSVR = zeros(Nval,Nreps);    % Prediction on validation set
legendText = cell(Nreps,1);  % Text for legend

%%
% Loop over different sample of training data:
for iter = 1:3

    % Randomly split the data into a training and a validation sets 
    idxTrain = randperm(N,Ntrain);
    idxValid = setdiff(1:N,idxTrain);
    Xtrain = X(idxTrain,:);
    Ytrain = Y(idxTrain);
    Xval = X(idxValid,:);
    Yval(:,iter) = Y(idxValid);
    
    % Select SVR as the metamodeling tool
    MetaOpts.Type = 'Metamodel';
    MetaOpts.MetaType = 'SVR';
    
    % Assign the training data set as the experimental design
    MetaOpts.ExpDesign.X = Xtrain;
    MetaOpts.ExpDesign.Y = Ytrain;
    
    % Use the L1-penalization scheme
    MetaOpts.Loss = 'l1-eps';
    
    % Use an anisotropic kernel
    MetaOpts.Kernel.Isotropic = 0;
    
    % Use the BFGS method for the hyperparameters calibration
    MetaOpts.Optim.Method = 'BFGS';
    
    % Use the SMO algorithm (if available) or IP algorithm 
    % to solve the quadratic programming problem
    MetaOpts.QPSolver = QPSolver;

    % Create the SVR metamodel
    mySVR = uq_createModel(MetaOpts);
    
    % Evaluate the SVR metamodel at the validation set
    YSVR(:,iter) = uq_evalModel(mySVR,Xval);
    
    % Create a text for legend
    legendText{iter} = sprintf('Iteration %i',iter);

end

%% 5 - VALIDATION
%
% Compare the SVR predictions at the validation set points
% against the true values over the $3$ repetitions:
uq_figure
uq_plot(Yval, YSVR, '+')
hold on
uq_plot([0 60], [0 60], 'k')
hold off
axis equal
axis([0 60 0 60])

uq_legend(legendText, 'Location', 'southeast')
xlabel('$\mathrm{Y_{true}}$')
ylabel('$\mathrm{Y_{SVR}}$')
