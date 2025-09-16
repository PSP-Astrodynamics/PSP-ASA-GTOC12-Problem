function success = uq_Reliability_test_SSER_multiOut(level)
% SUCCESS = UQ_RELIABILITY_TEST_SSER_multiOut(LEVEL):
%     Checks SSER functionality with multiple outputs.
%
% See also UQ_SELFTEST_UQ_RELIABILITY

success = 0;

%% Start test:
uqlab('-nosplash');
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| ' mfilename '...\n']);


%% set a seed
seed = 1;
rng(seed)

%% create the input and model
inputOpts.Marginals.Type = 'Gaussian';
inputOpts.Marginals.Parameters = [0 1];
myInput = uq_createInput(inputOpts);

mOpts.mHandle = @(X) ones(1,2) - X*ones(1,2);
mOpts.isVectorized = true;
myModel = uq_createModel(mOpts);


%% SSER analysis
% create reliability model
SSEROptions.Type = 'Reliability';           
SSEROptions.Method = 'SSER';                
SSEROptions.Model = myModel;                
SSEROptions.Input = myInput;                
SSEROptions.Display = 'standard';
SSEROptions.SSER.ExpansionOptions.TruncOptions.MaxInteraction = 2;
SSEROptions.SSER.ExpansionOptions.TruncOptions.qNorm = 0.7;
SSEROptions.SSER.ExpansionOptions.Degree = 0:2;
SSEROptions.SSER.Convergence.NRefine = 15;

% Experimental design
SSEROptions.SSER.ExpDesign.Sampling = 'Sequential';
SSEROptions.SSER.ExpDesign.NSamples = 150;
SSEROptions.SSER.ExpDesign.NEnrich = 15;

SSEROptions.Display = 0;

% try construction, should not work
try
    mySSERAnalysis = uq_createAnalysis(SSEROptions);
catch
    success = 1;
end

end