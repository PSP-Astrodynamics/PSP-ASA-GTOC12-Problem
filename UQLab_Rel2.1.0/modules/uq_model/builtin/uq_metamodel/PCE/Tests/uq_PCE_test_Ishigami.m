function pass = uq_PCE_test_Ishigami( level )
% PASS = UQ_PCE_TEST_ISHIGAMI(LEVEL): non-regression test for PCE based on
% the well-known Ishigami function.

ishigami_mu_exact =  3.5;
ishigami_std_exact = 3.7208;


eps = 1e-6;
pceMethods = {'OLS','LARS','OMP','Quadrature'};
% Initialize test:
pass = 1;
evalc('uqlab');
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_PCE_test_Ishigami...\n']);

%% INPUT
% values taken from the default phimecasoft example
% Define the probabilistic model.
for i = 1:3
    Input.Marginals(i).Type = 'Uniform' ;
    Input.Marginals(i).Parameters = [-pi, pi] ;
end

myInput = uq_createInput(Input);

%% MODEL
% Physical model: Ishigami function
modelopts.Name = 'ishigami test';
modelopts.mFile = 'uq_ishigami' ;
evalc('FullModel = uq_createModel(modelopts)');


%% PCE Metamodel
for ii = 1 : length(pceMethods)
clear metaopts

metaopts.Type = 'metamodel';
metaopts.MetaType = 'PCE';
metaopts.Input = myInput ;
metaopts.FullModel = FullModel;

metaopts.Method = pceMethods{ii};
metaopts.Degree = 14;

switch lower(metaopts.Method )
    case 'ols'
        metaopts.ExpDesign.Sampling = 'Sobol';
        metaopts.ExpDesign.NSamples = 2500;
        metaopts.TruncOptions.qNorm = 0.75;
    case 'lars'
        metaopts.ExpDesign.Sampling = 'Sobol';
        metaopts.ExpDesign.NSamples = 2500;
        metaopts.TruncOptions.qNorm = 0.75;
    case 'omp'
        metaopts.ExpDesign.Sampling = 'Sobol';
        metaopts.ExpDesign.NSamples = 2500;
        metaopts.TruncOptions.qNorm = 0.75;
    case 'quadrature'
        
end

evalc('myPCE = uq_createModel(metaopts)');

%% Validation
mu_est = myPCE.PCE.Coefficients(1);
std_est = norm(myPCE.PCE.Coefficients(2:end));

pass = pass & (abs(ishigami_mu_exact - mu_est) < eps & ...
    abs(ishigami_std_exact - std_est) );
end

%% Add a test for the custom truncation options
metaopts.TruncOptions = struct;
metaopts.TruncOptions.Custom = myPCE.PCE.Basis.Indices;
metaopts.Method = 'Quadrature';

myPCE_truncation = uq_createModel(metaopts);

%% compare now with the reference solution and assign the test result
pass = pass & ~max(myPCE_truncation.PCE.Coefficients - myPCE.PCE.Coefficients);

