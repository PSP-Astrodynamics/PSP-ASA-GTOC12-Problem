function pass = uq_LRA_test_CustomLRA( level )
% UQ_LRA_TEST_CUSTOMPCE( LEVEL )
% 
% Summary:
%   Test for the low rank approx model calculation.
%   A 'Custom' expansion - no calculation takes place.
% 
% Settings:
%   LEVEL = { 'normal', 'slow' }
% 
% Details:
%    Asserts that it is possible to set a custom basis function set and coefficients 
%    (user defined coefficients - without calculation) for a LRA meta-model.
%    First an LRA meta-model is calculated for the Ishigami function 
%    defined as:
%    
%        Y = sin(X_1) + \alpha sin^2(X_2) + \beta {X_3}^4 sin(X_1).
%    
%    A random uniform distribution is chosen for $ X_1 , X_2, X_3 $ and a 
%    metamodel is calculated with OLS for update and correction step.
%    The coefficients calculated are set to the metamodel with 
%    "custom" as method of calculation and the same results 
%    are retrieved as with the \texttt{OLS} computed model. 

% Initialize test:
pass = 1;
evalc('uqlab');
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_LRA_test_CustomLRA...\n']);

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
metaopts.ExpDesign.NSamples = 2500;
metaopts.TruncOptions.qNorm = 0.75;

evalc('myLRA = uq_createModel(metaopts);');


%% GENERATING A NEW CUSTOM MODEL JUST TO EVALUATE THE PREDICTOR
predopts.Type = 'Metamodel';
predopts.MetaType = 'LRA';
% specify the "Custom" PCE method
predopts.Method = 'Custom';

% specify the same input as for the other LRA
predopts.Input = myInput;

% and the relevant coefficients
predopts.LRA = myLRA.LRA;

% let's make it multidimensional just for the sake of testing
predopts.LRA(2) = predopts.LRA(1);

% generate the metamodel
evalc('LRApred = uq_createModel(predopts);');
%PCEpred = uq_createModel(predopts);

%% COMPARE PREDICTIONS FROM THE 
% get a validation sample
X = uq_getSample(1e5);
% predict the responses with the original metamodel
YLRA = uq_evalModel(myLRA,X);
% predict the same responses with the "custom" metamodel
YLRApred = uq_evalModel(LRApred,X);

% if they are identical to within machine precision, pass the test
pass = pass & (max(abs(YLRA-YLRApred(:,1))) < eps);
