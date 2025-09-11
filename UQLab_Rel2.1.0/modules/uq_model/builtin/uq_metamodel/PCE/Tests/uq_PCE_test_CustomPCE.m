function pass = uq_PCE_test_CustomPCE( level )
% UQ_PCE_TEST_CUSTOMPCE( LEVEL ): non-regression testing for custom PCE
% (predictor only)

 
% Summary:
%   Test for the polynomial expansion model calculation 
%   for a 'Custom' expansion. No calculation takes place.
% 
% Settings:
%   LEVEL = { 'normal', 'detailed' }
% 
% Details:
%    Asserts that it is possible to set a custom basis function set and coefficients 
%    (user defined coefficients - without calculation) for a PCE meta-model.
%    First a PCE meta-model is calculated for the Ishigami function 
%    defined as:
%    
%        Y = sin(X_1) + \alpha sin^2(X_2) + \beta {X_3}^4 sin(X_1).
%    
%    A random uniform distribution is chosen for $ X_1 , X_2, X_3 $ and a 
%    metamodel is calculated with the LARS method. The coefficients 
%    calculated with "LARS" are set to the metamodel with 
%    "custom" as method of calculation and the same results 
%    are retrieved as with the \texttt{lars} model. 

% Initialize test:
pass = 1;
evalc('uqlab');
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_PCE_test_CustomPCE...\n']);

%% INPUT
% values taken from the default phimecasoft example
% Define the probabilistic model.
for i = 1:3
    Input.Marginals(i).Type = 'Uniform' ;
    Input.Marginals(i).Parameters = [-1,1] ;
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

metaopts.Method = 'LARS';           % Or can be set to OMP as well
metaopts.Degree = 14;

% Test also that the 'arbitrary' option does not break the 
% 'custom' PCE:
metaopts.PolyTypes = {'arbitrary','legendre','legendre'};

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

evalc('myPCE = uq_createModel(metaopts);');


%% GENERATE A NEW CUSTOM PCE MODEL JUST TO EVALUATE THE PREDICTOR
predopts.Type = 'Metamodel';
predopts.MetaType = 'PCE';
% specify the "Custom" PCE method
predopts.Method = 'Custom';

% specify the same input as for the other PCE
predopts.Input = myInput;

% specify the basis for the PCE
PCEBasis.Indices = myPCE.PCE.Basis.Indices;
PCEBasis.PolyTypes = myPCE.PCE.Basis.PolyTypes;
PCEBasis.PolyTypesParams= myPCE.PCE.Basis.PolyTypesParams;
predopts.PCE.Basis = PCEBasis;

% and the relevant coefficients
predopts.PCE.Coefficients = myPCE.PCE.Coefficients;

% make it multidimensional just for the sake of testing
predopts.PCE(2) = predopts.PCE(1);

% generate the metamodel
evalc('PCEpred = uq_createModel(predopts);');

%% COMPARE PREDICTIONS FROM THE TWO MODEL
% get a validation sample
X = uq_getSample(1e5);
% predict the responses with the original metamodel
YPC = uq_evalModel(myPCE,X);
% predict the same responses with the "custom" metamodel
YPCpred = uq_evalModel(PCEpred,X);

%% TEST RESULTS (PREDICTORS IDENTICAL TO MACHINE PRECISION)
pass = pass & (max(abs(YPC-YPCpred(:,1))) < eps);
