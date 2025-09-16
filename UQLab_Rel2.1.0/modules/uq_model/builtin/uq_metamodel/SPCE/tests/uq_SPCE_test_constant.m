function pass = uq_SPCE_test_constant( level )
% PASS = UQ_SPCE_TEST_CONSTANT(LEVEL): check if the SPCE set-up works for
% constant input
uqlab('-nosplash');
rng(100,'twister')

% Initialize test:
pass = true;

if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| uq_SPCE_test_constant...\n']);

% acceptable relative error for the likelihood
AcceptEr = 0.2;
%% a computational model
modelopts.mFile = 'uq_GBM'; % specify the function name
modelopts.isStochastic = true; % set to stochastic
modelopts.isVectorized = true; % the function is vectorized
myModel = uq_createModel(modelopts, '-private');        % create the model object

%% INPUT
Input.Marginals(1).Name = 'mu';
Input.Marginals(1).Type = 'Constant';
Input.Marginals(1).Parameters = 0.1; 

Input.Marginals(2).Name = 'sigma';
Input.Marginals(2).Type = 'Uniform';
Input.Marginals(2).Parameters = [0.1,0.3]; 

Input.Marginals(3).Name = 'Const1';
Input.Marginals(3).Type = 'Constant';
Input.Marginals(3).Parameters = 0.5; 

Input.Marginals(4).Name = 'Const2';
Input.Marginals(4).Type = 'Constant';
Input.Marginals(4).Parameters = 0.5; 

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

if ~pass
    ErrStr = '\nError in uq_SPCE_test_constant\n';
    error(ErrStr)
end
