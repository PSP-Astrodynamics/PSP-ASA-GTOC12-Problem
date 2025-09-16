function pass = uq_Kriging_test_OptimResult( level )
% UQ_KRIGING_TEST_OPTIMRESULT non-regression and validation test of the available
% optimization methods for the Kriging module
%
% Summary:
% Makes sure that different optimization methods using either ML or CV
% estimation will converge to the correct minimum on some predefined
% problems
% 

%% Initialize test
pass = 1;
evalc('uqlab');

if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| uq_Kriging_test_OptimResult...\n']);

%% Check availability of some optimization methods

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

%% parameters
eps_rel = 1e-2;
rng(100);

CorrFamilyHandle.Separable = @(X1,X2,th) max(0, 1 - abs(X1-X2)/th);
CorrFamilyHandle.Ellipsoidal = @(h) max(0, 1 - h);
CorrFamilies = {'exponential',...
    'linear', 'gaussian', 'matern-3_2',...
    'matern-5_2', 'handle'};
CorrTypes = {'Separable','Ellipsoidal'};
IsotropyCases = {true, false};
estMethods = {'ml','cv'};
avoid_BFGS_optim = [2 3 6]; % Corr. family cases to avoid gradient based optimisation
Xtrain  = [ -1   -0.7143   -0.4286   -0.1429    0.1429    0.4286    0.7143 1]';
Ytrain = [0.0385    0.0727    0.1788    0.6622    0.6622    0.1788    0.0727  0.0385]';

% Get the indices of all possible combinations
combIdx = uq_findAllCombinations(CorrFamilies, CorrTypes, IsotropyCases, optMethods, estMethods);
% filter out the combinations that correspond to BFGS and families flaged
% as "avoid_BFGS_optim"
%accidx = ~(any(combIdx(:,1) == avoid_BFGS_optim,2) & combIdx(:,4) == 1);
if OPTIM_TOOLBOX_EXISTS
    for ii = 1:length(avoid_BFGS_optim)
        combIdx(combIdx(:,1)==avoid_BFGS_optim(ii) & combIdx(:,4) == 2,:) = []; 
    end
end
%combIdx = combIdx(accidx,:);

% for normal level randomly pick 20 cases
if strcmpi(level, 'normal')
   randidx = randperm(size(combIdx,1),20);
   combIdx = combIdx(randidx,:);
end

%% Create input
Input.Marginals.Type = 'Uniform' ;
Input.Marginals.Parameters = [-1, 1] ;
myInput = uq_createInput(Input);

%% general options
metaopts.Type = 'Metamodel';
metaopts.MetaType = 'Kriging';
metaopts.Input = myInput;
metaopts.ExpDesign.Sampling = 'user' ;
metaopts.ExpDesign.X = Xtrain ;
metaopts.ExpDesign.Y = Ytrain ;
metaopts.Scaling = 0;
metaopts.Optim.Bounds = [0.01; 3] ;
metaopts.Optim.InitialValue = 0.1;
metaopts.Optim.MaxIter = 30;
metaopts.Optim.Tol = 1e-7;

%% run the tests
for ii = 1 : size(combIdx,1)
    curr_idx = combIdx(ii,:);
    metaopts.Corr.Isotropic = IsotropyCases{curr_idx(3)};
    metaopts.Corr.Type = CorrTypes{curr_idx(2)};
    if strcmp('handle',CorrFamilies{curr_idx(1)})
        metaopts.Corr.Family = CorrFamilyHandle.(CorrTypes{curr_idx(2)});
    else
        metaopts.Corr.Family = CorrFamilies{curr_idx(1)};
    end
    metaopts.EstimMethod = estMethods{curr_idx(5)};
    metaopts.Optim.Method = optMethods{curr_idx(4)} ;
    metaopts.Optim.(upper(optMethods{curr_idx(4)})).nStall = 8;
    metaopts.Optim.(upper(optMethods{curr_idx(4)})).nLM = 80;
    metaopts.Optim.(upper(optMethods{curr_idx(4)})).nPop = 100;
    [~, KrigModel] = evalc('uq_createModel(metaopts)') ;
    thStar = KrigModel.Kriging(1).theta;
    thStar_TRUE = compute_true_theta_star(KrigModel);
    curr_error = abs(thStar - thStar_TRUE)/thStar_TRUE;
    fprintf('Family:%s, Type:%s, Isotropic:%i, Est.:%s, Optim:%s, Error:%.5f\n',...
        CorrFamilies{curr_idx(1)}, ...
        CorrTypes{curr_idx(2)}, ...
        IsotropyCases{curr_idx(3)}, ...
        estMethods{curr_idx(5)}, ...
        optMethods{curr_idx(4)}, ...
        curr_error)
    
    pass = pass & curr_error < eps_rel;

end


%% final test: custom correlation function
clear metaopts
metaopts.Type = 'Metamodel';
metaopts.MetaType = 'Kriging';
metaopts.Input = myInput;
metaopts.ExpDesign.Sampling = 'user' ;
metaopts.ExpDesign.X = Xtrain ;
metaopts.ExpDesign.Y = Ytrain ;
metaopts.Scaling = 0;
metaopts.Optim.Bounds = [0.01; 3] ;
metaopts.Optim.InitialValue = 0.1;
metaopts.Optim.MaxIter = 30;
metaopts.Optim.Tol = 1e-7;
metaopts.Optim.Method = 'cmaes';

metaopts.Corr.Handle = @myEvalR;

[~, KrigModel] = evalc('uq_createModel(metaopts)') ;

thStar = KrigModel.Kriging(1).theta;
thStar_TRUE = compute_true_theta_star(KrigModel);
curr_error = abs(thStar - thStar_TRUE)/thStar_TRUE;
fprintf('Custom correlation function test, Error:%.5f\n',...
    curr_error)

pass = pass & curr_error < eps_rel;

%% auxilliary functions (used during the selftest)
% 1) grid-based computation of true optimal theta
function theta_star = compute_true_theta_star(krgmdl)
    theta_grid = linspace(0.01,3,400);
    J = zeros(size(theta_grid));

    parameters.X = krgmdl.ExpDesign.U;
    parameters.Y = krgmdl.ExpDesign.Y;
    parameters.N = krgmdl.Internal.Runtime.N ;
    parameters.F = krgmdl.Internal.Kriging(1).Trend.F;
    parameters.trend_type = krgmdl.Internal.Kriging(1).Trend.Type;
    parameters.CorrOptions = krgmdl.Internal.Kriging(1).GP.Corr ;
    parameters.IsRegression = krgmdl.Internal.Regression(1).IsRegression;
    parameters.EstimNoise = krgmdl.Internal.Regression(1).EstimNoise;
    switch lower(krgmdl.Internal.Kriging(1).GP.EstimMethod)
        case 'ml'
            objFunHandle = str2func('uq_Kriging_eval_J_of_theta_ML') ;
        case 'cv'
            objFunHandle = str2func('uq_Kriging_eval_J_of_theta_CV') ;
            parameters.RandIdx = krgmdl.Internal.Runtime.CV.RandIdx;
    end
    
    for ii = 1 : length(theta_grid)
        J(ii) = objFunHandle(theta_grid(ii), parameters);
    end
    [~, min_idx] = min(J);
    theta_star = theta_grid(min_idx);


% 2) Custom correlation function specification
    function R = myEvalR(x1, x2, theta, parameters)
        CorrOptions.Type = 'separable';
        CorrOptions.Family = 'Matern-3_2';
        CorrOptions.Isotropic = false;
        CorrOptions.Nugget = 1e-2;
        R = zeros(size(x1,1), size(x2,1));
        R = uq_eval_Kernel( x1, x2, ...
    theta, CorrOptions);
        