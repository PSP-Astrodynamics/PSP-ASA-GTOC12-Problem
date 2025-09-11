function pass = uq_SVR_test_AllCombined( level )
%UQ_SVR_TEST_ALLCOMBINED test (most of) all possible combinations of
%major parameters. The search space has been reduced so that the results
%may not be meaningful. The aim here is only to make sure that everything
%wil run.
% Input : level 
%   - normal: all combined optimization algorithms with given kernel, loss,
%   estimmethod
%  - any other string, e.g. all: Combined optim, kernel, loss and
%  estimmethod. In total 210 models will be created (time-consuming yet
%  extensive test)

% Large value of tolerance 

% Initialize test:
pass = 1;
evalc('uqlab');
uq_retrieveSession;
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end

% Optim functions
% Check if the global optimization toolnbox exists
try
    % Make sure that the global optimization toolbox is avaialble
    GAoptions = gaoptimset;
    goptimization_check = true;
catch
    goptimization_check = false;
end
% Define the available optimization algorithms
if goptimization_check
    OptimMethod = {'CE','HCE','GA','HGA','BFGS','CMAES','HCMAES'};
else % Excluse GA and HGA is global optim toolbox is not available
    OptimMethod = {'CE','HCE','BFGS','CMAES','HCMAES'};
end


% Define all the test cases
if ~strcmpi(level, 'normal')
    LossTypes = {'l2-eps'} ;
    KernelFamilies = {'Linear_NS','Linear','polynomial','sigmoid','Gaussian','Exponential','Matern-3_2','Matern-5_2'} ;
    EstimMethod = {'SpanLOO', 'SmoothLOO','CV'} ;
    QPSolver = {'ip', 'smo'} ;
    combIdx = uq_findAllCombinations(LossTypes,KernelFamilies,EstimMethod,OptimMethod, QPSolver);
    % Issue a fprintf here warning that the computation of all the
    % combinations may take a lot of time
    for ii  = 1 : length(combIdx)
        % produce one different test-case for each combination
        testCases(ii).Loss = LossTypes{combIdx(ii,1)};
        testCases(ii).Kernel.Family = KernelFamilies{combIdx(ii,2)};
        testCases(ii).EstimMethod = EstimMethod{combIdx(ii,3)};
        testCases(ii).OptimMethod = OptimMethod{combIdx(ii,4)};
        testCases(ii).QPSolver = QPSolver{combIdx(ii,5)} ;
    end
else
    for ii = 1: length( OptimMethod)
        testCases(ii).Loss = 'l2-eps';
        testCases(ii).Kernel.Family = 'Matern-5_2';
        testCases(ii).EstimMethod = 'SpanLOO';
        testCases(ii).OptimMethod = OptimMethod{ii};   
        testCases(ii).QPSolver = 'ip' ;
    end
end

%% Start of the test
fprintf(['\nRunning: |' level '| uq_SVR_test_AllCombined...\n']);

%% Create the full model
model.Name = 'simple_1d';
model.mFile = 'uq_SVR_test_function_1d' ;
evalc('uq_createModel(model)');

%% Create inputs
Xtrain = linspace(-1,1,5)';
Ytrain = uq_evalModel(uq_getModel('simple_1d'),Xtrain);
X_pred = linspace(-1,1,10)' ;        
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
    metaopts.EstimMethod = testCases(nCase).EstimMethod ;
    metaopts.Optim.Method = testCases(nCase).OptimMethod ;
    metaopts.QPSolver = testCases(nCase).QPSolver ;
    metaopts.Optim.MaxIter = 2;

    if strcmpi(testCases(nCase).Kernel.Family,'linear_ns')
        metaopts.Optim.Bounds.C = [1; 100] ;
        metaopts.Optim.Bounds.epsilon = [1e-3; 1];
    elseif strcmpi(testCases(nCase).Kernel.Family,'polynomial')
        metaopts.Optim.Bounds.C = [1 ; 100] ;
        metaopts.Optim.Bounds.epsilon = [1e-3; 1] ;
        metaopts.Optim.Bounds.theta = [0.5 ; 2];
        metaopts.Hyperparameters.theta = [1.5] ;
        metaopts.Hyperparameters.polyorder = [2:3] ;
    elseif strcmpi(testCases(nCase).Kernel.Family,'sigmoid')
        metaopts.Optim.Bounds.C = [1; 10] ;
        metaopts.Optim.Bounds.epsilon = [1e-2; 1] ;
        metaopts.Optim.Bounds.theta = [0.9 -1.1; 1.1 -0.9];
    elseif any(strcmpi(testCases(nCase).Kernel.Family,{'linear','Gaussian','exponential','Matern-3_2','Matern-5_2'}))
        metaopts.Optim.Bounds.C = [1; 100] ;
        metaopts.Optim.Bounds.epsilon = [1e-3; 1] ;
        metaopts.Optim.Bounds.theta = [0.1; 2];
    end
    
    
%     metaopts.Scaling = scaling(ii);
    modelID = modelID + 1 ;
    %% Norm-1 loss
    metaopts.Name = ['mySVR_',num2str(modelID)];
    [~,mySVR] = evalc('uq_createModel(metaopts)');

    %% Calculate Predictions

    Y_svr = uq_evalModel(uq_getModel(['mySVR_',num2str(modelID)]),X_pred);
  
end
% If everything run fine until here, say thanks and return pass
pass = 1 ;
end
