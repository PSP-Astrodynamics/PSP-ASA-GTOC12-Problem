function pass = uq_Kriging_test_kFold(level)
%UQ_KRIGING_TEST_KFOLD tests for k-fold CV estimation procedure.
%
%   The tests make sure that the results of hyperparameters optimization
%   using cross-validation estimation with different number of folds in
%   Kriging calculation is consistent with the reference values (obtained
%   from fine grid optimization) are consistent with the reference values.
%
%   PASS = UQ_KRIGING_TEST_REGRESSION_OPTIMRESULT(LEVEL) tests Kriging
%   calculation using CV estimation with different number of folds. Return
%   true if all tests pass. Level either takes value of 'normal' (the
%   default) which only runs 10% of the overall possible tests,
%   or any other values which then runs everything (i.e., exhaustive).

%% Initialize the test

rng(52352,'twister')  % Reproducible results
uqlab('-nosplash')

if nargin < 1
    level = 'normal';
end

fprintf('\nRunning: |%s| uq_Kriging_test_kFold...\n', level);

%% Check availability of some optimization methods

% Required toolboxes for some optimization methods in the Kriging module
reqToolboxNames = {...
    'Optimization Toolbox',...
    'Global Optimization Toolbox'};
% Check 
[tbOk,tbNames] = uq_check_toolboxes();
optimToolboxExists = any(...
    strcmpi(reqToolboxNames{1},tbNames(tbOk)));
globalOptimToolboxExists = any(...
    strcmpi(reqToolboxNames{2},tbNames(tbOk)));

optMethods = {'cmaes'};  % CMAES is built-in

if optimToolboxExists
    optMethods = [optMethods 'bfgs' 'hcmaes'];
end
if globalOptimToolboxExists
   optMethods = [optMethods 'ga'];
end
if optimToolboxExists && globalOptimToolboxExists
    optMethods = [optMethods 'hga'];
end
% 'sade' and 'hsade' are no longer supported,
% but might be used for 'exhaustive' testing
if ~strcmpi(level,'normal')
    optMethods = [optMethods 'sade'];
    if optimToolboxExists
        optMethods = [optMethods 'hsade'];
    end
end

%% Define test parameters
%
eps_rel = 5.0e-2;

CorrFamilyHandle.Separable = @(X1,X2,th) max(0, 1 - abs(X1-X2)/th);
CorrFamilyHandle.Ellipsoidal = @(h) max(0, 1 - h);

corrFamilies = {...
    'exponential', 'linear', 'gaussian',...
    'matern-3_2', 'matern-5_2', 'handle'};
corrTypes = {'Separable','Ellipsoidal'};
isotropyCases = {true,false};

% Correlation families that should avoid gradient-based optimization
avoid_BFGS = [2 3 6];

% K-Fold cross-validation parameters
leaveKOuts = [1 2 3 4 5 6 7];
% NOTE: Avoid BFGS for some n-fold CV estimation scheme, because the
% landscape of the objective function has local minima, especially when
% left-out sample is large.
avoidBFGSForLKO = [4 5 6 7];

%% Define training data

% Experimental design
Xtrain = [-1; -0.7143; -0.4286; -0.1429; 0.1429; 0.4286; 0.7143; 1];
% Model responses
Ytrain = [0.0385; 0.0727; 0.1788; 0.6622; 0.6622; 0.1788; 0.0727; 0.0385];

%% Create test case combinations

% Get the indices of all possible combinations
combIdx = uq_findAllCombinations(corrFamilies, corrTypes, isotropyCases,...
    optMethods, leaveKOuts);
% Filter out the combinations that correspond to BFGS optimization
% and correlation families that are flagged as "avoid_BFGS_optim"
if optimToolboxExists
    for ii = 1:length(avoid_BFGS)
        combIdx(combIdx(:,4) == 2 & combIdx(:,1) == avoid_BFGS(ii),:) = []; 
    end
    % Avoid BFGS for some n-fold CV scheme
    for ii = 1:numel(avoidBFGSForLKO)
        combIdx(combIdx(:,4) == 2 & ...
            combIdx(:,5) == avoidBFGSForLKO(ii),:) = [];
    end
end

% For normal level randomly pick n Cases only
nCases = size(combIdx,1);
if strcmpi(level,'normal')
   nCases = ceil(0.01 * nCases);
   randIdx = randperm(size(combIdx,1),nCases);
   combIdx = combIdx(randIdx,:);
end

pass = false(nCases,1);

%% Display the header for the test iterations
LogicalString = {'false', 'true'};
headerString = {...
    'No.', 'Family', 'Type', 'Isotropic', 'Optim.',...
    'lKo', 'kFold',...
    'thetaOpt', 'thetaStar', 'relErrTheta',...
    'Success', 'Note'};
fprintf(...
    '\n%5s %12s %12s %9s %6s %4s %5s %9s %9s %11s %7s %5s \n',...
    headerString{:})
FormatString = ...
    '%5d %12s %12s %9s %6s %4i %5i %9.3e %9.3e %11.3e %7s %5s\n';

%% Define common options for the Kriging metamodel

% Kriging metamodel
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'Kriging';
MetaOpts.Display = 'quiet';
% Experimental design
MetaOpts.ExpDesign.X = Xtrain;
MetaOpts.ExpDesign.Y = Ytrain;
% Scaling option
MetaOpts.Scaling = false;
% Estimation method
MetaOpts.EstimMethod = 'cv';
% Optimization options
MetaOpts.Optim.Bounds = [1e-3; 3];
MetaOpts.Optim.InitialValue = 0.1;
MetaOpts.Optim.MaxIter = 30;
MetaOpts.Optim.Tol = 1e-7;  % BFGS needs a higher tolerance here

%% Run the tests
%
for ii = 1:nCases
    curr_idx = combIdx(ii,:);
    if strcmp('handle',corrFamilies{curr_idx(1)})
        MetaOpts.Corr.Family = CorrFamilyHandle.(corrTypes{curr_idx(2)});
    else
        MetaOpts.Corr.Family = corrFamilies{curr_idx(1)};
    end
    MetaOpts.Corr.Type = corrTypes{curr_idx(2)};
    MetaOpts.Corr.Isotropic = isotropyCases{curr_idx(3)};

    % Optimization method-specific options
    MetaOpts.Optim.Method = optMethods{curr_idx(4)};
    switch optMethods{curr_idx(4)}
        case {'cmaes', 'ga', 'sade'}
            MetaOpts.Optim.(upper(optMethods{curr_idx(4)})).nStall = 6;
            MetaOpts.Optim.(upper(optMethods{curr_idx(4)})).nPop = 120;
        case {'bfgs'}
            MetaOpts.Optim.(upper(optMethods{curr_idx(4)})).nLM = 10;
        case {'hcmaes', 'hga', 'hsade'}
            MetaOpts.Optim.(upper(optMethods{curr_idx(4)})).nStall = 6;
            MetaOpts.Optim.(upper(optMethods{curr_idx(4)})).nLM = 10;
            MetaOpts.Optim.(upper(optMethods{curr_idx(4)})).nPop = 120;
    end

    % K in Leave-K-Out
    MetaOpts.CV.LeaveKOut = leaveKOuts(curr_idx(5));

    % Create Kriging metamodel
    KrgModel = uq_createModel(MetaOpts);
    
    % Remove opt.method-specific options
    MetaOpts.Optim = rmfield(...
        MetaOpts.Optim,upper(optMethods{curr_idx(4)}));

    % Number of folds
    nClasses = ceil(KrgModel.ExpDesign.NSamples/leaveKOuts(curr_idx(5)));
    
    % Compare theta estimation
    thetaEst = KrgModel.Kriging.theta;
    JEst = KrgModel.Internal.Kriging.Optim.ObjFun;
    [thetaStar,JStar] = compute_trueThetaStar(KrgModel);
    thetaRelErr = abs(thetaEst - thetaStar) / thetaStar;
    JRelErr = abs(JEst - JStar)/JStar;
    pass(ii) = thetaRelErr < eps_rel;
    
    if ~pass(ii)
        % Sometimes objective function is plateaued around the minimum
        pass(ii) = JRelErr < eps_rel;
        note = 'plateau';
    else
        note = '       ';
    end

    % Print results
    fprintf(FormatString,...
        ii,...
        corrFamilies{curr_idx(1)},...
        corrTypes{curr_idx(2)},...
        LogicalString{isotropyCases{curr_idx(3)}+1},...
        optMethods{curr_idx(4)},...
        leaveKOuts(curr_idx(5)),...
        nClasses,...
        thetaEst,...
        thetaStar,...
        thetaRelErr,...
        LogicalString{pass(ii)+1},...
        note)

end

%% Additional test: custom correlation function

clear MetaOpts
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'Kriging';
MetaOpts.Display = 'quiet';

MetaOpts.ExpDesign.X = Xtrain;
MetaOpts.ExpDesign.Y = Ytrain;
MetaOpts.Scaling = false;

MetaOpts.Optim.Method = 'cmaes';
MetaOpts.Optim.Bounds = [1e-3; 3];
MetaOpts.Optim.InitialValue = 0.1;
MetaOpts.Optim.MaxIter = 30;
MetaOpts.Optim.Tol = 1e-7;

MetaOpts.Corr.Handle = @myEvalR;

MetaOpts.EstimMethod = 'cv';
MetaOpts.CV.LeaveKOut = 3;

KrgModel = uq_createModel(MetaOpts);

% Number of CV folds
nClasses = ceil(KrgModel.ExpDesign.NSamples/MetaOpts.CV.LeaveKOut);

% Compare theta estimation
thetaEst = KrgModel.Kriging.theta;
thetaStar = compute_trueThetaStar(KrgModel);
thetaRelErr = abs(thetaEst - thetaStar) / thetaStar;
pass(ii+1) = thetaRelErr < eps_rel;

% Print results
fprintf(FormatString,...
        ii+1,...
        'custom',...
        repmat(' ', 1, 12),...
        repmat(' ', 1, 9),...
        lower(KrgModel.Internal.Kriging.Optim.Method),...
        MetaOpts.CV.LeaveKOut,...
        nClasses,...
        thetaEst,...
        thetaStar,...
        thetaRelErr, LogicalString{pass(ii+1)+1})

pass = all(pass);

end

%% Helper functions

function R = myEvalR(x1, x2, theta, parameters)
    CorrOptions.Type = 'separable';
    CorrOptions.Family = 'Matern-3_2';
    CorrOptions.Isotropic = false;
    CorrOptions.Nugget = 1e-10;
    R = uq_eval_Kernel(x1, x2, theta, CorrOptions);
end

function [thetaStar,Jstar] = compute_trueThetaStar(krgMdl)
    theta_grid = linspace(0.01,3,400);
    J = zeros(size(theta_grid));

    parameters.X = krgMdl.ExpDesign.U;
    parameters.Y = krgMdl.ExpDesign.Y;
    parameters.N = krgMdl.Internal.Runtime.N ;
    parameters.F = krgMdl.Internal.Kriging(1).Trend.F;
    parameters.trend_type = krgMdl.Internal.Kriging(1).Trend.Type;
    parameters.CorrOptions = krgMdl.Internal.Kriging(1).GP.Corr ;
    parameters.IsRegression = krgMdl.Internal.Regression(1).IsRegression;
    parameters.EstimNoise = krgMdl.Internal.Regression(1).EstimNoise;
    switch lower(krgMdl.Internal.Kriging(1).GP.EstimMethod)
        case 'ml'
            objFunHandle = str2func('uq_Kriging_eval_J_of_theta_ML') ;
        case 'cv'
            objFunHandle = str2func('uq_Kriging_eval_J_of_theta_CV') ;
            parameters.RandIdx = krgMdl.Internal.Runtime.CV.RandIdx;
    end
    
    for ii = 1:length(theta_grid)
        J(ii) = objFunHandle(theta_grid(ii),parameters);
    end

    [Jstar,min_idx] = min(J);
    thetaStar = theta_grid(min_idx);
end