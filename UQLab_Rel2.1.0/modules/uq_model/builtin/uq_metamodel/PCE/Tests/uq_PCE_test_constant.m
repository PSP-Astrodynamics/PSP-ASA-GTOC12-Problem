function success = uq_PCE_test_constant(level)
% pass = UQ_PCE_TEST_CONSTANT(LEVEL): Non-regression test to assert that
% the constant type dimensions are respected throughout PCE evaluation.
% 
% Tested PCE computation methods:
% 1) OLS 
% 2) LARS
% 3) Quadrature
% 4) OMP
%
% The test also intends to enforce consistency in the treatment of
% constants in the book-keeping level.
%
% Test what is tested:
% 
%   1) The constant variables are recognised and retained in input
%   2) propagation of the "constant" flag to the ED_Input field
%   3) Mean and variance of a PCE model with contants is computed
%      correctly.

%% TEST SETUP:

%% Input setup:

Eps = 1e-3;
pceMethods = {'OLS','LARS','Quadrature','OMP'};
% Initialize test:
pass = 1;
evalc('uqlab');
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_PCE_test_constant...\n']);

%% INPUT
Input.Marginals(1).Type = 'Uniform' ;
Input.Marginals(1).Parameters = [-1, 1] ;

Input.Marginals(2).Type = 'Constant' ;
Input.Marginals(2).Parameters = 3.2;

Input.Marginals(3).Type = 'Gaussian' ;
Input.Marginals(3).Parameters = [0, pi] ;

Input.Marginals(4).Type = 'Constant' ;
Input.Marginals(4).Parameters = 2.3;

Input.Marginals(5).Type = 'Uniform' ;
Input.Marginals(5).Parameters = [-1, 1] ;


% Test the created input too:
myInput = uq_createInput(Input);

if ~all(myInput.nonConst == [1 3 5])
    error('The constant variables were not recognized during PCE input creation.')
end

% take a small sample and assert that the fixed constant variables are what
% they should be:
evalc('test_sample = uq_getSample(100);');
if ~all(test_sample(:,2) == 3.2) || ~all(test_sample(:,4)==2.3)
    error('The constant variables are not set correctly during the input module creation.')
end

%% 5D Model Creation for testing:
% A model where we can easily derive the results analytically is chosen.
% In the present version of UQLab model-level fixing of parameters is not 
% supported and it may not be in the future as well.
fullmodelopts.Name = '5D testing model';
fullmodelopts.mHandle = @(X) X(:,1) + 2 * X(:,2) + 3 * X(:,3) + 4 * X(:,4) + 5 * X(:,5);
fullmodelopts.isVectorized = true;
evalc('FullModel = uq_createModel(fullmodelopts)');

%% PCE Computation Setup:
metaopts.Type = 'Metamodel';
metaopts.MetaType = 'PCE';
metaopts.Input = myInput;
metaopts.FullModel = FullModel;
metaopts.TruncOptions.qNorm = 1;
metaopts.Degree = 5;

% Prepare method specific metaopts for the PCE computation:
EDopts.Sampling = 'Sobol';
EDopts.NSamples = 100;
% OLS:
metaopts_ols = metaopts;
metaopts_ols.Method = 'OLS';
metaopts_ols.ExpDesign = EDopts;

% LARS:
metaopts_lars = metaopts;
metaopts_lars.Method = 'LARS';
metaopts_lars.ExpDesign = EDopts;

% OMP:
metaopts_omp = metaopts;
metaopts_omp.Method = 'OMP';
metaopts_omp.ExpDesign = EDopts;

% Quadrature:
metaopts_quad = metaopts;
metaopts_quad.Method = 'Quadrature';
metaopts_quad.Degree = 5;

%% MODEL CALCULATION:
evalc('myPCE_OLS = uq_createModel(metaopts_ols);');
evalc('myPCE_LARS = uq_createModel(metaopts_lars);');
evalc('myPCE_OMP = uq_createModel(metaopts_omp);');
evalc('myPCE_Quad = uq_createModel(metaopts_quad);');

all_models = {myPCE_OLS, myPCE_LARS, myPCE_Quad, myPCE_OMP};

%% TEST:
% Now start asserting the constants were absolutely 
% respected and that there are no inconsistencies 
% that might introduce bugs in the further management 
% of the metamodels:
tests = cell(1,1);
for kk = 1:length(all_models)
    curr_model = all_models{kk};
    
    % Test the 'constant' flag is propagated consistently throughout
    % Input/ED_Input and model:
    % Input -> ED_Input
    t1_1 = strcmpi(curr_model.Internal.ED_Input.Marginals(2).Type,'constant');
    t1_2 = strcmpi(curr_model.Internal.ED_Input.Marginals(4).Type,'constant');
    t1 = t1_1 && t1_2;
    t1 = {t1, 'propagation of the "constant" flag to the ED_Input field'};
    
    %Check that the indices of the constants are kept track of:
    t2 = all(curr_model.Internal.Runtime.nonConstIdx == [1 3 5]);
    t2 = {t2,'Indexing of nonConstIdx propagated properly'};
    
    % Assert the mean and variance of the models have the correct values:
    mod_mean = (2*3.2 + 4*2.3);
    mod_var  = 1/12 * (2^2+10^2)+(3*pi)^2;
    t3 = all(([curr_model.PCE.Moments.Mean curr_model.PCE.Moments.Var] - [mod_mean, mod_var])<Eps );
    t3 = {t3,'Mean and variance are calculated correctly.'};
    
    t4 = (size(curr_model.PCE.Basis.Indices,2) - size(myInput.nonConst,2) == 0) ;
    t4 = { t4, 'The polynomial basis is of correct size.' } ;
    test_total = {t1,t2,t3,t4};
    tests{kk,1} = test_total;
end

% Test that bootstrap is computable when a 'constant' has been set.
metaopts_lars.Bootstrap.Replications = 10;
boot_model = uq_createModel(metaopts_lars);

% PCE Evaluation tests:
% 1) The corect Constant dimensions are neglected
% 2) The correct polyTypes are used
X_val = uq_getSample(100);
% Test again that we sample correctly (the constant dimensions are
% still the correct constants)
t1 = (all(X_val(:,2) == 3.2) && all(X_val(:,4)));
t1 = {t1, 'After model creation the correct input is used.'};

Y_full = uq_evalModel(FullModel,X_val);

for kk = 1:length(all_models)
    curr_model = all_models{kk};
    % Acquire a sample to calculate the model with:
    
    Y_mod = uq_evalModel(curr_model,X_val);
    t2 = all(abs(Y_full - Y_mod)<Eps);
    t2 = {t2,'Evaluating the model after calculation produces the correct output.'};
    test2{kk} = t2 ;
end

% Print a summary:
for kk = 1:length(tests)
    curr_method = pceMethods{kk};
    for test_idx = 1:length(tests{kk,1})
        success = tests{kk,1}{test_idx}{1};
        if ~success
            tname   = tests{kk,1}{test_idx}{2};
            error('PCE with %s test "%s" failed!',curr_method,tname);
        end
    end
end
success = t1{1} ;
if ~success
    error('PCE test "%s" failed!',t1{2}) ;
end
for kk= 1:length(all_models)
    curr_method = pceMethods{kk};
    success = test2{kk}{1};
    if ~success
        tname = test2{kk}{2} ;
        error('PCE with %s test "%s" failed!',curr_method, tname) ;
    end
end
end