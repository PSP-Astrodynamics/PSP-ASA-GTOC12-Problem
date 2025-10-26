function pass = uq_SVR_test_Kernel( level )
% UQ_SVR_TEST_Kernel Regression test for SVR kernel function
% Two models are built using known hyperparameters. The SVR coefficients are
% with values as computed by the model as of 05.12.2018 (before relase 1.1)

% Error threshold
eps = 1e-2;
nvalidation = 1000 ;
X_pred = linspace(-1,1,nvalidation)' ;

% Initialize test:
pass = 1;
evalc('uqlab');
uq_retrieveSession;
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_SVR_test_Kernel...\n']);


%% Create the full model
model.Name = 'simple_1d';
model.mFile = 'uq_SVR_test_function_1d' ;
evalc('uq_createModel(model)');
%% Create inputs
Xtrain = linspace(-1,1,8)';
Ytrain = uq_evalModel(uq_getModel('simple_1d'),Xtrain);
% Run the tests for both scaled and unscaled versions:

clear metaopts;
%% general options
metaopts.Type = 'Metamodel';
metaopts.MetaType = 'SVR';
metaopts.ExpDesign.X = Xtrain ;
metaopts.ExpDesign.Y = Ytrain ;
% Given parameters
metaopts.Kernel.Family = 'Linear_NS' ;
metaopts.Kernel.Isotropic = true ;
metaopts.Kernel.Type = 'separable' ;
metaopts.Kernel.Nugget = 0 ;
metaopts.Hyperparameters.C = 1.2445 ;
metaopts.Hyperparameters.epsilon = 0.01 ;
metaopts.Optim.Method = 'none';
metaopts.OutputScaling = 0 ;
metaopts.Scaling = 0;

%% Gaussian Kernel
rng(10,'twister');
[~,SVR_Linear_NS] = evalc('uq_createModel(metaopts, ''-private'')');
Kpred1 = uq_eval_Kernel( Xtrain, X_pred, [], metaopts.Kernel);

metaopts.Kernel.Family = 'Gaussian' ;
metaopts.Hyperparameters.theta = 0.2857 ;
rng(10,'twister');
[~,SVR_Gaussian] = evalc('uq_createModel(metaopts, ''-private'')');

%% Calculate Predictions
% First evaluate the model using coefficients and bias as computed by the
% SVR module in version 1.0 (15.05.2018)

% Support vector coefficients alpha - alpha*
beta1 = [ 1.244499999999999
  -1.244500000000000
  -1.244500000000000
   1.244500000000000
   1.244500000000000
  -1.244500000000000
  -1.244500000000000
   1.244499999999999] ;
% Bias term
b1 =0.408224688367471 ;
% Prediction
Y_pred1 = transpose(beta1) * Kpred1 + b1 ;



% Support vector coefficients alpha - alpha*
beta2 = [   0.716952009770083
    -1.244499999880112
    0.298889018991054
    0.228658971118975
    0.228658971118975
    0.298889018991054
    -1.244499999880112
    0.716952009770083] ;
% Bias term
b2 = 0.484778745145011 ;
Kpred2 = uq_eval_Kernel( Xtrain, X_pred, metaopts.Hyperparameters.theta, metaopts.Kernel);

% Prediction
Y_pred2 = transpose(beta2) * Kpred2 + b2 ;



% Evaluate the model through UQLab
Y_linNS = uq_evalModel(SVR_Linear_NS,X_pred);
Y_Gauss = uq_evalModel(SVR_Gaussian,X_pred);

%% make sure that predictions coincide with SVR model as implemented in 07/16
pass = pass & mean(abs(Y_linNS - Y_pred1')) < eps;
pass = pass & mean(abs(Y_Gauss - Y_pred2')) < eps;
