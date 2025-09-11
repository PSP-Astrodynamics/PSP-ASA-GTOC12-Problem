function pass = uq_PCE_test_adaptqNormMaxInter( level )
% PASS = UQ_PCE_TEST_ADAPTQNORMINTER(LEVEL): running test for qNorm
% adaptive PCE and check if MaxInteraction is correctly included when both
% is speciified.

% Initialize test:
pass = 1;
evalc('uqlab');
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_PCE_test_adaptqNormMaxInter...\n']);

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
maxinter = 1:3;

for ii = 1 : length(maxinter)
clear metaopts

metaopts.Type = 'metamodel';
metaopts.MetaType = 'PCE';
metaopts.Input = myInput ;
metaopts.FullModel = FullModel;
metaopts.ExpDesign.NSamples = 200;

metaopts.TruncOptions.MaxInteraction = maxinter(ii);
metaopts.TruncOptions.qNorm = 0.6:0.1:0.9;

evalc('myPCE = uq_createModel(metaopts)');

%% Validation
% check the multi indices
NofVars = sum(myPCE.PCE.Basis.Indices~=0,2);

pass = pass & ~sum(NofVars>maxinter(ii));
end
