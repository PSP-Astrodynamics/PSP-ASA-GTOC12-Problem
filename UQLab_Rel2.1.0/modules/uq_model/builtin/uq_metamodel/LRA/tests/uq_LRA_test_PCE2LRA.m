function pass = uq_LRA_test_LRA2PCE( level )
% UQ_LRA_TEST_LRA2PCE( LEVEL )
% 
% Summary:
%   Test for the transformation of PCE coefficients to LRA coefficients.
%   
% Settings:
%   LEVEL = { 'normal', 'detailed' }
% 
% Details:
%    Asserts that it is possible to cast a PCE model as an LRA model.
%    First a PCE meta-model is calculated for the Ishigami function 
%    defined as:
%    
%        Y = sin(X_1) + \alpha sin^2(X_2) + \beta {X_3}^4 sin(X_1).
%    
%    A random uniform distribution is chosen for $ X_1 , X_2, X_3 $ and a 
%    metamodel is calculated with OLS for update and correction step.
%    The model is cast to a LRA model with uq_PCE_to_LRA and it is asserted
%    that the model evaluation results are approximately the same between 
%    the two models.
% 
%    It currently depends on the Sandia labs implementation of the
%    CANDECOMP/PARAFAC (cp) decomposition of a tensor, therefore in case
%    the corresponding needed functions are not existent it returns 'pass'
%    without running.

if ~exist('cp_als')
    % The test is not run - it will fail because the tensor toolbox is not
    % existent.
    pass = true;
    return;
end

ishigami_mu_exact =  3.5;
ishigami_std_exact = 3.7208;

% Initialize test:
pass = 1;
evalc('uqlab');
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_LRA_test_LRA2PCE...\n']);

%% INPUT
% values taken from the default phimecasoft example
% Define the probabilistic model.
for i = 1:3
    Input.Marginals(i).Type = 'Uniform' ;
    Input.Marginals(i).Parameters = [-pi,pi] ;
end

myInput = uq_createInput(Input);

%% MODEL
% Physical model: Ishigami function
modelopts.Name = 'ishigami test';
modelopts.mFile = 'uq_ishigami' ;
evalc('FullModel = uq_createModel(modelopts)');


%% PCE Metamodel: create an original metamodel
clear metaopts

metaopts.Type = 'Metamodel';
metaopts.MetaType = 'PCE';
metaopts.Input = myInput ;
metaopts.FullModel = FullModel;

% Options relevant to the LRA computation
metaopts.Degree = 14;

% In the initial implementation the arbitrary polynomials needed some
% special treatment. Although the issue is resolved it does not harm to
% test them also here:
metaopts.PolyTypes = {'legendre','legendre','legendre'};

metaopts.ExpDesign.Sampling = 'Sobol';
metaopts.ExpDesign.NSamples = 500;
metaopts.TruncOptions.qNorm = 0.75;

evalc('myPCE = uq_createModel(metaopts);');

% Assert that the LRA to PCE method does not result to an error:
try 
    myLRA = uq_PCE_to_LRA(myPCE,2);
catch me
    error('PCE to LRA failed.');
end

% Get a sample:
Xtest = uq_getSample(1e3);
Ypce = uq_evalModel(myPCE,Xtest);
Ylra = uq_evalModel(myLRA,Xtest);
err = sqrt(sum(Ypce - Ylra).^2)/1e3;
pass = err<1e-5;

uq_display(myLRA);
uq_display(myPCE);