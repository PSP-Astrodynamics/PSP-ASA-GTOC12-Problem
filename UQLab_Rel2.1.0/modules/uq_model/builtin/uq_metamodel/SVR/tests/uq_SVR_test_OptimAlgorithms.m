function pass = uq_SVR_test_OptimAlgorithms( level )
%UQ_KRIGING_TEST_TRENDTYPES Non-regression for Kriging trends
%   In the first part all the diffrerent options of Kriging.Trend.Type
%   are tested and in the second part it is made sure that regression
%   result is correct.
eps = 1e-1;

% Initialize test:
pass = 1;
evalc('uqlab');
uq_retrieveSession;
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_SVR_test_OptimAlgorithms...\n']);
% Check whether global optimizatoin toolbox is available to include GA in
% the self-test
try
    % Make sure that the global optimization toolbox is avaialble
    GAoptions = gaoptimset;
    goptimization_check = true;
catch
    goptimization_check = false;
end
if goptimization_check
      OptimMethod = {'CE','GS','CMAES','GA','BFGS','HCMAES'};
else
    % No global optimization toolbox --> remove GA from the self-test
    OptimMethod = {'CE','GS','CMAES','BFGS','HCMAES'};
end

if ~strcmpi(level, 'normal')
    PenalTypes = {'l1-eps','l2-eps'} ;
    % Here testing only the stationary kernels. A non-stationary kernel is
    % tested in uq_SVR_test_kernel.
    KernelFamilies = {'linear','Gaussian','Exponential','Matern-3_2','Matern-5_2'} ;
    EstimMethod = {'SpanLOO', 'SmoothLOO', 'CV'} ;
    if goptimization_check
        OptimMethod = {'CE','GS','CMAES','GA','BFGS','HCMAES','HCE','HGA'};
    else
        % No global optim tooblox --> remove GA and HGA from the self-test
        OptimMethod = {'CE','GS','CMAES','BFGS','HCMAES','HCE'};
    end
    combIdx = uq_findAllCombinations(PenalTypes,KernelFamilies,EstimMethod,OptimMethod);
    % Issue a fprintf here warning that the computation of all the
    % combinations may take a lot of time
    for ii  = 1 : length(combIdx)
        % produce one different test-case for each combination
        testCases(ii).Loss = PenalTypes{combIdx(ii,1)};
        testCases(ii).Kernel.Family = KernelFamilies{combIdx(ii,2)};
        testCases(ii).EstimMethod = EstimMethod{combIdx(ii,3)};
        testCases(ii).OptimMethod = OptimMethod{combIdx(ii,4)};
        
    end
else
    for ii = 1: length( OptimMethod)
        testCases(ii).Loss = 'l2-eps';
        testCases(ii).Kernel.Family = 'Matern-5_2';
        testCases(ii).EstimMethod = 'SpanLOO';
        testCases(ii).OptimMethod = OptimMethod{ii};
    end
end
%% Create the full model
model.Name = 'simple_1d';
model.mFile = 'uq_SVR_test_function_1d' ;
evalc('uq_createModel(model)');
%% Create inputs
rng(100,'twister');
Xtrain = linspace(-1,1,10)';
Ytrain = uq_evalModel(uq_getModel('simple_1d'),Xtrain);
nvalidation = 500 ;
X_pred = linspace(-1,1,nvalidation)' ;
Y_true = uq_evalModel(uq_getModel('simple_1d'),X_pred);
% Run the tests for both scaled and unscaled versions:
% scaling = [0, 1]; % For now disregard the scaled one until scaling scheme is decided
scaling = 1;
modelID = 0;
for nCase = 1 : length(testCases)
    clear metaopts;
    %% general options
    metaopts.Type = 'Metamodel';
    metaopts.MetaType = 'SVR';
    metaopts.ExpDesign.X = Xtrain ;
    metaopts.ExpDesign.Y = Ytrain ;
    %Given parameters
    metaopts.Loss = testCases(nCase).Loss ;
    metaopts.Kernel = testCases(nCase).Kernel ;
    metaopts.EstimMethod = testCases(nCase).EstimMethod;
    metaopts.Optim.Method = testCases(nCase).OptimMethod;
    modelID = modelID + 1;
    
    %% Norm-1 loss
    metaopts.Name = ['mySVR_',num2str(modelID)];
    [~,mySVR] = evalc('uq_createModel(metaopts)');
    
    %% Calculate Predictions
    
    Y_class = uq_evalModel(uq_getModel(['mySVR_',num2str(modelID)]),X_pred);
    
    %% make sure that predictions coincide with SVR model as implemented in 07/16
    pass = pass & mean( Y_class .* Y_true < 0) < eps;
end
