function pass = uq_SVR_test_LossTypes( level )
% UQ_SVR_TEST_LOSSTYPES Regression test for SVR loss functions
% The model is built using known hyperparameters. The SVR coefficients are
% with values as computed by the model as of 15.05.2018 version 1.0

% Error threshold
eps = 1e-5;

% Initialize test:
pass = 1;
evalc('uqlab');
uq_retrieveSession;
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_SVR_test_LossTypes...\n']);


%% Create the full model
model.Name = 'simple_1d';
model.mFile = 'uq_SVR_test_function_1d' ;
evalc('uq_createModel(model)');
%% Create inputs
Xtrain = linspace(-1,1,8)';
Ytrain = uq_evalModel(uq_getModel('simple_1d'),Xtrain);
nvalidation = 1000 ;
% Run the tests for both scaled and unscaled versions:

clear metaopts;
%% general options
metaopts.Type = 'Metamodel';
metaopts.MetaType = 'SVR';
metaopts.ExpDesign.X = Xtrain ;
metaopts.ExpDesign.Y = Ytrain ;
% Given parameters
metaopts.Kernel.Family = 'Gaussian' ;
metaopts.Kernel.Isotropic = true ;
metaopts.Kernel.Type = 'separable' ;
metaopts.Kernel.Nugget = 0 ;
metaopts.Hyperparameters.C = 1.2445 ;
metaopts.Hyperparameters.epsilon = 0.01 ;
metaopts.Hyperparameters.theta = 0.2857 ;
metaopts.Optim.Method = 'none';
metaopts.OutputScaling = 0 ;
s = rng(10,'twister');
metaopts.Scaling = 0;

%% Norm-1 loss
rng(s);
metaopts.Loss = 'l1-eps' ;
[~,L1_SVR] = evalc('uq_createModel(metaopts, ''-private'')');
%% Norm 2 loss
rng(s);
metaopts.Loss = 'l2-eps' ;
[~,L2_SVR] =  evalc('uq_createModel(metaopts, ''-private'')');

%% Calculate Predictions
% First evaluate the model using coefficients and bias as computed by the
% SVR module in version 1.0 (15.05.2018)
X_pred = linspace(-1,1,nvalidation)' ;
Kpred = uq_eval_Kernel( Xtrain, X_pred, metaopts.Hyperparameters.theta, metaopts.Kernel);
% Support vector coefficients alpha - alpha*
beta1 = [   0.716952009770083
    -1.244499999880112
    0.298889018991054
    0.228658971118975
    0.228658971118975
    0.298889018991054
    -1.244499999880112
    0.716952009770083] ;
% Bias term
b1 = 0.484778745145011 ;
% Prediction
Y_pred1 = transpose(beta1) * Kpred + b1 ;

% Support vector coefficients alpha - alpha*
beta2 = [   0.202221696996625
    -0.436415863795266
    -0.005414257684838
    0.239608424483479
    0.239608424483479
    -0.005414257684838
    -0.436415863795266
    0.202221696996625] ;
% Bias term
b2 = 0.387964038750996 ;
% Prediction
Y_pred2 = transpose(beta2) * Kpred + b2 ;

% Evaluate the model through UQLab
Y_l1_svr = uq_evalModel(L1_SVR,X_pred);
Y_l2_svr = uq_evalModel(L2_SVR,X_pred);

%% make sure that predictions coincide with SVR model as implemented in 07/16
pass = pass & mean(abs(Y_l1_svr - Y_pred1')) < eps;
pass = pass & mean(abs(Y_l2_svr - Y_pred2')) < eps;
