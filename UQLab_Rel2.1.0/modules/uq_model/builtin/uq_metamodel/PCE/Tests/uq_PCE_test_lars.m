function pass = uq_PCE_test_lars( level )
% PASS = UQ_PCE_TEST_LARS(LEVEL): test whether LARS deals properly with
% constant regressors.

% Initialize test:
evalc('uqlab');
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
% Print out running message
fprintf(['\nRunning: |' level '| uq_PCE_test_lars...\n']);

pass = 1;

%% Model and input: Ishigami function
modelopts.mFile = 'uq_ishigami' ;      % specify the function name
myModel = uq_createModel(modelopts);   % create and add the model object to UQLab

for ii = 1 : 3
    Input.Marginals(ii).Type = 'Uniform' ;
    Input.Marginals(ii).Parameters = [-pi, pi] ; 
end
myInput = uq_createInput(Input);

%% TEST TREATMENT OF CONSTANT REGRESSORS
degree = 4;

metaOpts.Type = 'Metamodel';
metaOpts.MetaType = 'PCE';
metaOpts.Method = 'LARS';
metaOpts.Input = myInput;

X = uq_getSample(myInput, 100, 'Sobol');
Y = uq_evalModel(myModel, X);
metaOpts.ExpDesign.X = X;
metaOpts.ExpDesign.Y = Y;

% Regular PCE of total degree ...
allindices = uq_generate_basis_Apmj(0:degree, 3);
ind_last = size(allindices, 1);
metaOpts.TruncOptions.Custom = full(allindices);

myPCE1 = uq_createModel(metaOpts);

%% Switch last and first basis element
allindices(1,:) = allindices(ind_last,:); 
allindices(ind_last,:) = [0 0 0]; 
metaOpts.TruncOptions.Custom = full(allindices);

myPCE2 = uq_createModel(metaOpts);

% The two solutions should be the same, test on a new sample
Nval = 1e2;
Xval = uq_getSample(myInput, Nval, 'Sobol');

YPCE1 = uq_evalModel(myPCE1, Xval);
YPCE2 = uq_evalModel(myPCE2, Xval);

pass = pass & (norm(myPCE1.PCE.Coefficients(1:end) - myPCE2.PCE.Coefficients([ind_last, 2:ind_last-1, 1])) < 1e-12);
pass = pass & (norm(YPCE1 - YPCE2)/sqrt(Nval) < 1e-12);

%% several constant elements should not change anything
allindices(ind_last + 1,:) = [0 0 0];% a second constant term
allindices(ind_last + 2,:) = [0 0 0];% a third constant term
metaOpts.TruncOptions.Custom = full(allindices);

myPCE3 = uq_createModel(metaOpts);

YPCE3 = uq_evalModel(myPCE3, Xval);
pass = pass & (norm(myPCE1.PCE.Coefficients(1:end) - myPCE3.PCE.Coefficients([ind_last, 2:ind_last-1, 1])) < 1e-12);
pass = pass & (norm(YPCE1 - YPCE3)/sqrt(Nval) < 1e-12);

%% Equal weighting should not change anything
allindices(end-1:end,:) = []; % remove extra constant regressors
% Assign weights so that the constant term has value 2:
metaOpts.ExpDesign.CY = diag(0.25*ones(size(X,1),1)); 
metaOpts.TruncOptions.Custom = full(allindices);
myPCE4 = uq_createModel(metaOpts);

YPCE4 = uq_evalModel(myPCE4, Xval);
pass = pass & (norm(myPCE1.PCE.Coefficients(1:end) - myPCE4.PCE.Coefficients([ind_last, 2:ind_last-1, 1])) < 1e-12);
pass = pass & (norm(YPCE1 - YPCE4)/sqrt(Nval) < 1e-12);

%% Try no constant regressor... removing the mean of PCE1 from the data
% not sure if this makes sense as a test
allindices = full(uq_generate_basis_Apmj(0:degree, 3));
allindices(1,:) = []; % remove constant regressor
metaOpts.TruncOptions.Custom = allindices;
metaOpts.ExpDesign = rmfield(metaOpts.ExpDesign, 'CY');
meanY = myPCE1.PCE.Moments.Mean;
metaOpts.ExpDesign.Y = Y - meanY;
myPCE5 = uq_createModel(metaOpts);

YPCE5 = meanY + uq_evalModel(myPCE5, Xval);
pass = pass & (norm(myPCE1.PCE.Coefficients - [meanY; myPCE5.PCE.Coefficients]) < 1e-12);
pass = pass & (norm(YPCE1 - YPCE5)/sqrt(Nval) < 1e-12);

%% TEST NON-HYBRID UQ_LAR

U = myPCE1.ExpDesign.U;
univ_p_val = uq_PCE_eval_unipoly(myPCE1, U); % UQlab builtin function
Psi = uq_PCE_create_Psi(myPCE1.PCE.Basis.Indices, univ_p_val);

coeffs_true = zeros(size(Psi,2),1);
coeffs_true([1 3 7 11 23]) = [3.4 -2.1 0.7 1.8 -4.4];
Y = Psi*coeffs_true;
%%
options.hybrid_lars = 1;
options.normalize = 1;
options.early_stop = 1;
options.loo_modified = 1;
options.loo_hybrid = 1;

results1 = uq_lar(Psi, Y, options);
coeffs1 = results1.coefficients;
pass = pass & (norm(coeffs1 - coeffs_true) < 1e-12);
%% test normalization for original (non-hybrid) LARS
options.hybrid_lars = 0;
options.loo_hybrid = 0;

options.normalize = 1;
results2 = uq_lar(Psi, Y, options);
coeffs2 = results2.coefficients;
pass = pass & (norm(coeffs2 - coeffs_true) < 1e-12);

options.normalize = 0;
results2 = uq_lar(Psi, Y, options);
coeffs2 = results2.coefficients;
pass = pass & (norm(coeffs2 - coeffs_true) < 1e-12);

%% test weight matrix for original (non-hybrid) LARS
options.CY = diag(0.25*ones(size(Psi,1),1));

options.normalize = 1;
results3 = uq_lar(Psi, Y, options);
coeffs3 = results3.coefficients;
pass = pass & (norm(coeffs3 - coeffs_true) < 1e-12);

options.normalize = 0;
results3 = uq_lar(Psi, Y, options);
coeffs3 = results3.coefficients;
pass = pass & (norm(coeffs3 - coeffs_true) < 1e-12);

%% remove constant regressor
Y = Y - coeffs_true(1) * Psi(:,1);
Psi(:,1) = [];
options = rmfield(options, 'CY');

options.normalize = 1;
results4 = uq_lar(Psi, Y, options);
coeffs4 = results4.coefficients;
pass = pass & (norm(coeffs4 - coeffs_true(2:end)) < 1e-12);

options.normalize = 0;
results4 = uq_lar(Psi, Y, options);
coeffs4 = results4.coefficients;
pass = pass & (norm(coeffs4 - coeffs_true(2:end)) < 1e-12);

end

