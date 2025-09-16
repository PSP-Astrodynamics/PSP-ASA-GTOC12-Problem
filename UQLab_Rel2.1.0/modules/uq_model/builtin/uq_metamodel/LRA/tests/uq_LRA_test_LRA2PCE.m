function pass = uq_LRA_test_LRA2PCE( level )
% UQ_LRA_TEST_LRA2PCE( LEVEL )
% 
% Summary:
%   Test for the transformation of LRA coefficients to PCE coefficients.
%   
% Settings:
%   LEVEL = { 'normal', 'slow' }
% 
% Details:
%    Asserts that it is possible to cast an LRA model as a PCE model.
%    First an LRA meta-model is calculated for the Ishigami function 
%    defined as:
%    
%        Y = sin(X_1) + \alpha sin^2(X_2) + \beta {X_3}^4 sin(X_1).
%    
%    A random uniform distribution is chosen for $ X_1 , X_2, X_3 $ and a 
%    metamodel is calculated with OLS for update and correction step.
%    The model is cast to a PCE model with uq_LRA_to_PCE and it is asserted
%    that the model evaluation results are exactly the same between the two
%    models.

% Initialize test:
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
metaopts.MetaType = 'LRA';
metaopts.Input = myInput ;
metaopts.FullModel = FullModel;

% Options relevant to the LRA computation
metaopts.Degree = 5;
metaopts.Rank = 10;
metaopts.RankSelection.Method = 'CV';
metaopts.RankSelection.NFolds  = 3;
metaopts.CorrStep.MinDerrStop = 10^-15;
metaopts.CorrStep.MaxIterStop = 1000;
metaopts.CorrStep.Method = 'OLS';
metaopts.UpdateStep.Method = 'OLS';

% In the initial implementation the arbitrary polynomials needed some
% special treatment. Although the issue is resolved it does not harm to
% test them also here:
metaopts.PolyTypes = {'arbitrary','legendre','legendre'};

metaopts.ExpDesign.Sampling = 'Sobol';
metaopts.ExpDesign.NSamples = 500;

evalc('myLRA = uq_createModel(metaopts);');

% Assert that the LRA to PCE method does not result to an error:
try 
    myPCE = uq_LRA_to_PCE(myLRA);
catch me
    error('LRA to PCE failed.');
end

% Get a sample:
Xtest = uq_getSample(1e3);
Ypce = uq_evalModel(myPCE,Xtest);
Ylra = uq_evalModel(myLRA,Xtest);
err = sqrt(sum(Ypce - Ylra).^2);
pass = err<1e-10;
