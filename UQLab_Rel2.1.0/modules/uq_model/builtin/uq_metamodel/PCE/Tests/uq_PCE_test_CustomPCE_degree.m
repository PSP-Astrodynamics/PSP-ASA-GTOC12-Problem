function pass = uq_PCE_test_CustomPCE_degree( level )
% UQ_PCE_TEST_CUSTOMPCE_DEGREE( LEVEL ): testing the computation of degree
% for custom PCE (custom basis as well as custom PCE)
 
% Summary:
% There are two "custom" options for PCE:
% 1) Computing a PCE with a custom basis by specifying
% MetaOpts.TruncOpts.Custom = ...
% 2) Creating a custom PCE by specifying coefficients, indices, PolyTypes
% etc (no computation takes place)
%
% There were some problems in the computation of the degree for these
% expansions. This test checks whether the reported degree is correct.
% 
% Settings:
%   LEVEL = { 'normal' }
% 

% Initialize test:
pass = 1;
evalc('uqlab');
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_PCE_test_CustomPCE_degree...\n']);

%% INPUT
for i = 1:3
    Input.Marginals(i).Type = 'Uniform' ;
    Input.Marginals(i).Parameters = [2,4] ;
end

myInput = uq_createInput(Input);

%% MODEL
% Something simple
modelOpts.mHandle = @(X) X(:,1).^2 .* sqrt(X(:,2))+ X(:,3).^2;
myModel = uq_createModel(modelOpts);


%% First test regression-based PCE with CUSTOM BASIS
clear metaopts

metaopts.Type = 'Metamodel';
metaopts.MetaType = 'PCE';
metaopts.Input = myInput ;
metaopts.FullModel = myModel;

metaopts.Method = 'LARS';           % Or can be set to OMP as well

% specify the basis for the PCE
userBasis = [0 0 0;...
             1 0 0;...
             0 1 0;...
             1 1 0;...
             2 2 1;...
             ];
%%%% metaOpts.Degree = 5; % Do not specify the degree of the user-defined basis!
metaopts.TruncOptions.Custom = userBasis;

% Test also that the 'arbitrary' option does not break the 
% 'custom' PCE:
metaopts.PolyTypes = {'arbitrary','legendre','legendre'};

metaopts.ExpDesign.Sampling = 'Sobol';
metaopts.ExpDesign.NSamples = 100;
metaopts.TruncOptions.qNorm = 0.75;

metaopts.Display = 0;

% generate the metamodel
myPCE = uq_createModel(metaopts);

% Final degree is computed in uq_PCE_calculate_coefficients
pass = pass & (myPCE.PCE.Basis.Degree == 5);
% Internally, the MaxDegree is equal to the maximal univariate degree
pass = pass & (myPCE.Internal.PCE.MaxDegree == 2);
% not more than 3 
pass = pass & (size(myPCE.PCE.Basis.PolyTypesAB{1}{1}, 1) == 3);
pass = pass & (size(myPCE.PCE.Basis.PolyTypesAB{2}{1}, 1) == 3);
pass = pass & (size(myPCE.PCE.Basis.PolyTypesAB{3}{1}, 1) == 3);



%% Now define a CUSTOM PCE
predopts.Type = 'Metamodel';
predopts.MetaType = 'PCE';
% specify the "Custom" PCE method
predopts.Method = 'Custom';

% specify the same input as for the other PCE
predopts.Input = myInput;

predopts.Display = 0;

% specify the basis for the PCE
PCEBasis.Indices = myPCE.PCE.Basis.Indices;
PCEBasis.PolyTypes = myPCE.PCE.Basis.PolyTypes;
PCEBasis.PolyTypesParams= myPCE.PCE.Basis.PolyTypesParams;
predopts.PCE.Basis = PCEBasis;

% and the relevant coefficients
predopts.PCE.Coefficients = myPCE.PCE.Coefficients;

% generate the metamodel
PCEpred = uq_createModel(predopts);

% Univariate degree
pass = pass & (PCEpred.PCE(1).Basis.Degree == 2);
pass = pass & (PCEpred.PCE(1).Basis.qNorm == 1);
pass = pass & all(PCEpred.PCE(1).Basis.MaxCompDeg == [1 1 0]);

%% Again with different coefficients
predopts.PCE.Coefficients = ones(size(predopts.PCE.Coefficients));
% generate the metamodel
PCEpred2 = uq_createModel(predopts);

pass = pass & (PCEpred2.PCE.Basis.Degree == 2);
pass = pass & (PCEpred2.PCE.Basis.qNorm == 1);
pass = pass & all(PCEpred2.PCE.Basis.MaxCompDeg == [2 2 1]);

