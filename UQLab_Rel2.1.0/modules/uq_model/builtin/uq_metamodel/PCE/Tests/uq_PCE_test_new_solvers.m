function pass = uq_PCE_test_new_solvers(level)
% PASS = UQ_PCE_TEST_NEWSOLVERS(LEVEL) non-regression test for two versions 
% of Subspace pursuit (SP) (LOO and 5-fold CV for hyperparameter selection)
% and for BCS (10 and 4 folds)

evalc('uqlab');
if nargin < 1
    level = 'normal'; % Level 'normal' will only run the smaller degree
end
% Print out running message
fprintf(['\nRunning: |' level '| uq_PCE_test_new_solvers...\n']);

rng(1); % important for k-fold SP and BCS - they use random assignment of folds!!

pass = 1;

%% Model and input: Ishigami function
modelopts.mFile = 'uq_ishigami' ;      % specify the function name
myModel = uq_createModel(modelopts);   % create and add the model object to UQLab

for ii = 1 : 3
    Input.Marginals(ii).Type = 'Uniform' ;
    Input.Marginals(ii).Parameters = [-pi, pi] ; 
end
myInput = uq_createInput(Input);


%% Create an experimental design
N = 150;
X = uq_getSample(myInput, N, 'Sobol');
Y = uq_evalModel(myModel, X);

%% Ground truth for SP
coeff_indices_loo = [1, 4, 6, 13, 16, 20, 22, 35, 38, 43, 47, 52, 58, 87, ...
    90, 98, 122, 166, 173, 180, 185, 222, 284];
coeffs_loo = zeros(286, 1);
coeffs_loo(coeff_indices_loo) = [3.500219e+00, 1.624722e+00, -5.943162e-01,...
    -1.291035e+00, 1.371950e+00, -1.248295e-03, -1.951727e+00, 1.679790e-03, ...
    1.958034e-01, -1.090038e+00, 4.083320e-01, 1.518027e-03, 1.358396e+00, ...
    -1.120792e-02, -3.248491e-01, 1.657922e-01, -3.381399e-01, -1.126289e-03, ...
    5.040697e-02, -8.800704e-04, -8.136414e-03, 4.745394e-02, -1.689173e-03];

coeff_indices_kfold = [1, 4, 6, 13, 16, 22, 38, 43, 47, 52, 58, 87, 90, 98, ...
    122, 173, 185, 222];
coeffs_kfold = zeros(286,1);
coeffs_kfold(coeff_indices_kfold) = [3.499825e+00, 1.624773e+00, -5.949431e-01, ...
    -1.290977e+00, 1.372470e+00, -1.952087e+00, 1.952796e-01, -1.089699e+00, ...
    4.092343e-01, 2.018255e-03, 1.357933e+00, -1.186440e-02, -3.244946e-01, ...
    1.647020e-01, -3.387413e-01, 4.958405e-02, -9.332166e-03, 4.687659e-02];

coeff_indices_bcs = [1, 4, 6, 13, 16, 22, 26, 38, 43, 47, 58, 87, 90, 98, 122, 150, 173, 185, 195, 222];
coeffs_bcs = zeros(286,1);
coeffs_bcs(coeff_indices_bcs) = [3.500109e+00, 1.625212e+00, -5.948372e-01, ...
    -1.291316e+00, 1.373176e+00, -1.951420e+00, -1.308417e-03, 1.940613e-01, ...
    -1.089991e+00, 4.104854e-01, 1.358131e+00, -1.272430e-02, -3.235620e-01, ...
    1.639981e-01, -3.389884e-01, 1.826645e-03, 5.023396e-02, -9.455454e-03, ...
    -1.467832e-03, 4.671034e-02];

%% Setup of PCE (same for all)
metaopts.Display = 0;
metaopts.Type = 'Metamodel';
metaopts.MetaType = 'PCE';
metaopts.Degree = 10;
metaopts.Input = myInput;
metaopts.FullModel = myModel;
metaopts.ExpDesign.X = X;
metaopts.ExpDesign.Y = Y;

%% SP with LOO for hyperparameter selection (default)
metaopts.Method = 'SP';
myPCE1 = uq_createModel(metaopts);

pass = pass & (sum(myPCE1.PCE.Coefficients~=0) == 23);
pass = pass & (norm(coeffs_loo - myPCE1.PCE.Coefficients) < 1e-6);

%% SP with 5-fold CV for hyperparameter selection
metaopts.SP.CVMethod = 'kfold';
% Default: 5 folds
rng(1); % fix folds
myPCE2 = uq_createModel(metaopts);

pass = pass & (sum(myPCE2.PCE.Coefficients~=0) == 18);
pass = pass & (norm(coeffs_kfold - myPCE2.PCE.Coefficients) < 1e-6);  

%% BCS
rng(1); % fix folds
metaopts.Method = 'BCS';
metaopts = rmfield(metaopts, 'SP');
myPCE3 = uq_createModel(metaopts);

pass = pass & (sum(myPCE3.PCE.Coefficients~=0) == 20);
pass = pass & (norm(coeffs_bcs - myPCE3.PCE.Coefficients) < 1e-6);  
%% BCS
rng(1);
metaopts.Method = 'BCS';
metaopts.BCS.NumFolds = 4; % instead of default 10
myPCE4 = uq_createModel(metaopts);

pass = pass & (myPCE4.Error.LOO ~= myPCE3.Error.LOO); % different number 
% of folds --> different error estimate
pass = pass & (sum(myPCE4.PCE.Coefficients~=0) == 20);
pass = pass & (norm(coeffs_bcs - myPCE4.PCE.Coefficients) < 1e-6);  

end
