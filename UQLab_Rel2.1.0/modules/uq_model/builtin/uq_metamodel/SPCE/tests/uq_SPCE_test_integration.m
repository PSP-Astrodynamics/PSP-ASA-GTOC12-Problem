function pass = uq_SPCE_test_integration( level )
% PASS = UQ_SPCE_TEST_INTEGRATION(LEVEL): check if the SPCE set-up works for
% different integration methods
uqlab('-nosplash');
rng(100,'twister')

% Initialize test:
pass = true;

if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_SPCE_test_integration...\n']);

% acceptable relative error for the likelihood
AcceptEr = 0.2;
%% a computational model
modelopts.mFile = 'uq_GBM'; % specify the function name
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

%% Get training samples and the associated likelihood
X = uq_getSample(myInput,400);
Y = uq_evalModel(myModel,X);
NLLh = uq_GBM_NLL(X,Y);

XVal = uq_getSample(myInput,1000);
YVal = uq_evalModel(myModel,XVal);
NLLhVal = uq_GBM_NLL(XVal,YVal);

%% Setup for options for SPCE
metaopts.Type = 'metamodel';
metaopts.MetaType = 'SPCE';
metaopts.Input = myInput;
metaopts.Latent.Type = 'Gaussian';
metaopts.Degree = 1:2;
metaopts.TruncOptions.qNorm = [0.5,1];

metaopts.ExpDesign.X = X;
metaopts.ExpDesign.Y = Y;
metaopts.ValidationSet.X = XVal;
metaopts.ValidationSet.Y = YVal;

%% Check quadrature integration method
metaopts.IntMethod = 'Quadrature';
mySPCEQuad = uq_createModel(metaopts);

if abs((mySPCEQuad.Error.Nloglikelihood - NLLh)/NLLh)>AcceptEr ...
        || abs((mySPCEQuad.Error.Val.NLoglikelihood - NLLhVal)/NLLhVal)>AcceptEr
    pass = false;
end
%% Check sampling method
metaopts.IntMethod = 'Sampling';
metaopts.Degree = mySPCEQuad.SPCE.Basis.Degree;
metaopts.TruncOptions.qNorm = mySPCEQuad.SPCE.Basis.qNorm;

mySPCESamp = uq_createModel(metaopts);
if abs((mySPCESamp.Error.Nloglikelihood - NLLh)/NLLh)>AcceptEr ...
        || abs((mySPCESamp.Error.Val.NLoglikelihood - NLLhVal)/NLLhVal)>AcceptEr
    pass = false;
end
%% Check Matlab built-in integral
metaopts.IntMethod = 'MatlabInt';
metaopts.Sigma.Value = mySPCESamp.SPCE.Sigma;
mySPCEMatInt = uq_createModel(metaopts);

if abs((mySPCEMatInt.Error.Nloglikelihood - NLLh)/NLLh)>AcceptEr ...
        || abs((mySPCEMatInt.Error.Val.NLoglikelihood - NLLhVal)/NLLhVal)>AcceptEr
    pass = false;
end

if ~pass
    ErrStr = '\nError in uq_SPCE_test_integration\n';
    error(ErrStr)
end
