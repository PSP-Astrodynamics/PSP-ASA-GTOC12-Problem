function pass = uq_Kriging_test_GPROptimResult(level)
%UQ_KRIGING_TEST_GPROPTIMRESULT tests for optim. methods in GP regression.
%
%   The tests make sure that the results of hyperparameters optimization
%   using different optimization methods with either ML or CV estimation  
%   in Kriging regression are consistent with the reference values.
%
%   PASS = UQ_KRIGING_TEST_REGRESSION_OPTIMRESULT(LEVEL) tests the
%   available optimization methods in the Kriging module to create a 
%   regression model.

%   The test function is a simple one-dimensional function with noisy
%   output from which sample points are generated for the experimental
%   design. The number of sample points depends on the level of the test.
%   The test parameters are:
%       1) Training data (2): 1-dimensional or 3-dimensional.
%       2) Correlation families (6): 'exponential', 'linear', 'gaussian',
%          'matern-3_2', 'matern-5_2', 'handle'.
%       3) Types of correlation function (2): 'separable' or 'ellipsoidal'.
%       4) Isotropy of correlation function (2): true or false
%       5) Optimization methods (6): 
%           - built-in: 'cmaes','sade'
%           - with Optimization Toolbox: 'bfgs', 'hcmaes', 'hsade'
%           - with Global Optimization Toolbox: 'ga'
%           - with both toolboxes: 'hga'
%       6) Estimation method (2): 'ml' or 'cv'
%
%   Additionally a correlation function is used to test passing 
%   a correlation handle directly to to MetaOpts.Corr.Handle option.
%   Note that this is different than passing a handle to
%   MetaOpts.Corr.Family where it is expected that the handle is
%   one-dimensional.
%
%   For each test case, the steps are as follows:
%       1) Create a Kriging regression model to estimate the noise level.
%       2) Compare the noise level with the reference value
%       3) The test is passed if the difference of the noise level 
%          and its reference is below epsilon (EPS_REL).
%
%   Finally, note that the relative error for noise level estimation
%   depends on the number of data points. The higher the number of data
%   points, the better the estimation (but it also takes longer to train).

%% Initialize the test
%
uqlab('-nosplash')

if nargin < 1
    level = 'normal';
end

fprintf('\nRunning: |%s| uq_Kriging_test_GPROptimResult...\n', level);

%% Check availability of some optimization methods
%
% Required toolboxes for some optimization methods in the Kriging module
req_toolbox_names = {'Optimization Toolbox',...
    'Global Optimization Toolbox'};
% Check 
[ret_checks, ret_names] = uq_check_toolboxes();
OPTIM_TOOLBOX_EXISTS = any(strcmpi(req_toolbox_names{1},...
    ret_names(ret_checks)));
GOPTIM_TOOLBOX_EXISTS = any(strcmpi(req_toolbox_names{2},...
    ret_names(ret_checks)));

optMethods = {'cmaes'};  % CMAES is built-in

if OPTIM_TOOLBOX_EXISTS
    optMethods = [optMethods 'bfgs' 'hcmaes'];
end
if GOPTIM_TOOLBOX_EXISTS
   optMethods = [optMethods 'ga'];
end
if OPTIM_TOOLBOX_EXISTS && GOPTIM_TOOLBOX_EXISTS
    optMethods = [optMethods 'hga'];
end
% 'sade' and 'hsade' are no longer supported,
% but might be used for 'exhaustive' testing
if ~strcmpi(level,'normal')
    optMethods = [optMethods 'sade'];
    if OPTIM_TOOLBOX_EXISTS
        optMethods = [optMethods 'hsade'];
    end
end
%% Define test parameters
%


CorrFamilyHandle.Separable = @(X1,X2,th) max(0, 1 - abs(X1-X2)/th);
CorrFamilyHandle.Ellipsoidal = @(h) max(0, 1 - h);

corrFamilies = {'exponential', 'linear', 'gaussian',...
    'matern-3_2', 'matern-5_2', 'handle'};
corrTypes = {'Separable','Ellipsoidal'};
isotropyCases = {true,false};
estMethods = {'ml','cv'};

% Correlation families that should avoid gradient-based optimization
avoid_BFGS = [2 3 6]; 

% Correlation families that should avoid 3D function
avoid_3D = [1 2 6];

%% Define training data
%
% Experimental design, inputs and outputs
rng(52352,'twister')  % Reproducible data points
% For normal level use small sample
if strcmpi(level,'normal')
    Ntrain = 50;
    eps_rel = 2.0;
else
    Ntrain = 500;
    eps_rel = 1.0e-1;
end
noise_ref = [0.2 3];
% Training inputs
Xtrain1D = linspace(-10, 10, Ntrain)';
Xtrain3D = [-pi+2*pi*rand(Ntrain,1),...
    -pi+2*pi*rand(Ntrain,1),...
    -pi+2*pi*rand(Ntrain,1)];
Xtrain = {Xtrain1D, Xtrain3D};
% Training outputs
Ytrain1D = 1 + Xtrain1D*5e-2 + sin(Xtrain1D) ./ Xtrain1D + ...
    noise_ref(1)*randn(Ntrain,1);
Ytrain3D = uq_ishigami(Xtrain3D) + noise_ref(2) * randn(Ntrain,1);
Ytrain = {Ytrain1D, Ytrain3D};

%% Create test case combinations
%
% Get the indices of all possible combinations
combIdx = uq_findAllCombinations(corrFamilies, corrTypes, isotropyCases,...
    optMethods, estMethods, Ytrain);
% Filter out the combinations that correspond to BFGS optimization
% and correlation families that are flagged as "avoid_BFGS_optim"
if OPTIM_TOOLBOX_EXISTS
    for ii = 1:length(avoid_BFGS)
        combIdx(combIdx(:,4) == 3 & combIdx(:,1) == avoid_BFGS(ii),:) = []; 
    end
end
% Filter out combinations that correspond to estimation of 3D noisy
% function
for ii = 1:length(avoid_3D)
    combIdx(combIdx(:,6) == 2 & combIdx(:,1) == avoid_3D(ii),:) = [];
end

% For normal level randomly pick n Cases only
if strcmpi(level,'normal')
   rng shuffle  % shuffle random tests selection
   nCases = ceil(0.1 * size(combIdx,1));
   randIdx = randperm(size(combIdx,1),nCases);
   combIdx = combIdx(randIdx,:);
else
    nCases = size(combIdx,1);
end

pass = false(nCases,1);

%% Display the header for the test iterations
LogicalString = {'false', 'true'};
headerString = {'No.', '# Dim.', 'Family', 'Type', 'Isotropic',...
    'Est.', 'Optim.', 'SigmaN', 'Rel.Err.SigmaN', 'Success'};
NumDimString = {'1', '3'};
fprintf('\n%5s %7s %12s %12s %9s %4s %6s %10s %14s %7s\n', headerString{:})
FormatString = '%5d %7s %12s %12s %9s %4s %6s %10.3e %14.3e %7s\n';

%% Define common options for the Kriging metamodel
%
% Kriging metamodel
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'Kriging';
MetaOpts.Display = 'quiet';
% Regression option
MetaOpts.Regression.SigmaNSQ = 'auto';
% Scaling option
MetaOpts.Scaling = 0;
% Optimization options
MetaOpts.Optim.Bounds = [1e-3; 10];
MetaOpts.Optim.InitialValue = 0.1;
MetaOpts.Optim.MaxIter = 20;
MetaOpts.Optim.Tol = 1e-4;

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
    MetaOpts.Optim.Method = optMethods{curr_idx(4)};
    MetaOpts.EstimMethod = estMethods{curr_idx(5)};
    MetaOpts.ExpDesign.X = Xtrain{curr_idx(6)};
    MetaOpts.ExpDesign.Y = Ytrain{curr_idx(6)};

    KrigModel = uq_createModel(MetaOpts);
    
    % Compare noise level estimation
    sigmaNoiseError = ...
        abs((sqrt(KrigModel.Kriging.sigmaNSQ)-noise_ref(curr_idx(6)))) ...
        / noise_ref(curr_idx(6));
    pass(ii) = sigmaNoiseError < eps_rel;
    % Print results
    fprintf(FormatString,...
        ii,...
        NumDimString{curr_idx(6)},...
        corrFamilies{curr_idx(1)},...
        corrTypes{curr_idx(2)},...
        LogicalString{isotropyCases{curr_idx(3)}+1},...
        estMethods{curr_idx(5)},...
        optMethods{curr_idx(4)}, ...
        sqrt(KrigModel.Kriging.sigmaNSQ),...
        sigmaNoiseError, LogicalString{pass(ii)+1})
end

%% Additional test: custom correlation function
%
clear MetaOpts
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'Kriging';
MetaOpts.Display = 'quiet';

MetaOpts.Regression.SigmaNSQ = 'auto';

MetaOpts.ExpDesign.X = Xtrain{1};
MetaOpts.ExpDesign.Y = Ytrain{1};
MetaOpts.Scaling = 0;

MetaOpts.Optim.Method = 'cmaes';
MetaOpts.Optim.Bounds = [1e-3; 10];
MetaOpts.Optim.InitialValue = 0.1;
MetaOpts.Optim.MaxIter = 100;
MetaOpts.Optim.Tol = 1e-7;

MetaOpts.Corr.Handle = @myEvalR;

KrigModel = uq_createModel(MetaOpts);
% Compare noise level estimation
sigmaNoiseError = abs((sqrt(KrigModel.Kriging.sigmaNSQ)-noise_ref(1)) ...
    / noise_ref(1));
pass(ii+1) = sigmaNoiseError < eps_rel;
% Print results
fprintf(FormatString,...
        ii+1,...
        NumDimString{1},...
        'custom',...
        repmat(' ', 1, 12),...
        repmat(' ', 1, 9),...
        'ml',...
        lower(KrigModel.Internal.Kriging.Optim.Method), ...
        sqrt(KrigModel.Kriging.sigmaNSQ),...
        sigmaNoiseError, LogicalString{pass(ii)+1})

pass = all(pass);

end

function R = myEvalR(x1, x2, theta, parameters)
    CorrOptions.Type = 'separable';
    CorrOptions.Family = 'Matern-3_2';
    CorrOptions.Isotropic = false;
    CorrOptions.Nugget = 1e-10;
    R = uq_eval_Kernel( x1, x2, theta, CorrOptions);
end
