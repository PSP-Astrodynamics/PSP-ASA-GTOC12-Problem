function pass = uq_SPCE_test_MultiOutput( level )
% PASS = UQ_SPCE_TEST_MULTIOUTPUT(LEVEL): check if the SPCE set-up works for
% multi-output
uqlab('-nosplash');
rng(100,'twister')

% Initialize test:
pass = true;

if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_SPCE_test_MultiOutput...\n']);

% acceptable relative error for the likelihood
AcceptEr = 0.02;
%% a computational model with several response values
modelopts.mFile = 'uq_GBM_MultiOutputs'; % specify the function name
modelopts.isStochastic = true; % set to stochastic
modelopts.isVectorized = true; % the function is vectorized
myModel = uq_createModel(modelopts, '-private');        % create the model object

%% INPUT
Input.Marginals(1).Name = 'mu';
Input.Marginals(1).Type = 'Uniform';
Input.Marginals(1).Parameters = [0,0.2]; 

Input.Marginals(2).Name = 'sigma';
Input.Marginals(2).Type = 'Uniform';
Input.Marginals(2).Parameters = [0.1,0.3];  

myInput = uq_createInput(Input, '-private');

%% Setup for options for SPCE
metaopts.Type = 'metamodel';
metaopts.MetaType = 'SPCE';
metaopts.FullModel = myModel;
metaopts.Input = myInput;
metaopts.Latent.Type = 'Gaussian';
metaopts.Degree = 1:2;
metaopts.TruncOptions.qNorm = [0.5,1];

metaopts.ExpDesign.NSamples = 400;
metaopts.ExpDesign.Sampling = 'LHS';
%% Check quadrature integration method
metaopts.IntMethod = 'Quadrature';
mySPCEQuad = uq_createModel(metaopts);

uq_print(mySPCEQuad,1);
uq_display(mySPCEQuad,[1,2]);
close(gcf);
close(gcf);
%% Evaluate error metrics
XVal = uq_getSample(myInput,10);
YVal = uq_evalModel(myModel,XVal,1e3);
Metrics = uq_SPCE_evalModelSampleMetrics(mySPCEQuad,XVal,YVal);

if any([Metrics.NormalizedWSD]>AcceptEr)
    pass = false;
end

if ~pass
    ErrStr = '\nError in uq_SPCE_test_MultiOutput\n';
    error(ErrStr)
end
