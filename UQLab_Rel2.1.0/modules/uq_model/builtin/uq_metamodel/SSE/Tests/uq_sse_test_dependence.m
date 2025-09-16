function [success] = uq_sse_test_dependence(level)
% UQ_SSE_TEST_DEPENDENCE
%
%   See also: UQ_SELFTEST_UQ_SSE

%% START UQLAB
uqlab('-nosplash');
rng(130)
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| ',mfilename,'...\n']);
% init
success = 1;

%% PROBLEM SETUP
%% create the input
for ii = 1:2
    inputOpts.Marginals(ii).Type = 'Gaussian';
    inputOpts.Marginals(ii).Parameters = [0 1];
end
myInput = uq_createInput(inputOpts);

%% create the computational model
MOpts.mFile = 'uq_fourbranch';
MOpts.isVectorized = true;

myModel = uq_createModel(MOpts);
% make third input marginal constant
inputOpts = myInput.Options;
inputOpts.Copula.Type = 'Gaussian';
inputOpts.Copula.Parameters = [ 1 0.8 ; 0.8 1 ];
myInput = uq_createInput(inputOpts);

%% SSE Options
metaOpts.Type = 'metamodel';
metaOpts.MetaType = 'SSE';
metaOpts.Input = myInput;
% number of total model evaluations
metaOpts.ExpOptions.TruncOptions.MaxInteraction = 2;
metaOpts.ExpOptions.TruncOptions.qNorm = 0.5:0.1:0.8;
metaOpts.ExpOptions.Degree = 0:2;
metaOpts.Refine.NExp = 5;

% Experimental design
metaOpts.ExpDesign.X = uq_getSample(myInput,200);
metaOpts.ExpDesign.Y = uq_evalModel(myModel,metaOpts.ExpDesign.X);

%% CREATE SSE
mySSE = uq_createModel(metaOpts);

%% TEST some things
try
  X = uq_getSample(1e3);
  YSSE = uq_evalModel(mySSE,X);
  Y = uq_evalModel(myModel,X);
  
  uq_print(mySSE)
  
  % check that error is below threshold
  thresh = 2e-2;
  if mean((Y-YSSE).^2)/var(Y) > thresh
      error('Metamodel not sufficiently accurate')
  end
  success = success*1;
catch
  success = 0;
end

%% Try constructing SSE again, but with enabled post-processing
% PostProcessing
metaOpts.PostProcessing.OutputMoments = true;

try
    %% CREATE SSE
    mySSE = uq_createModel(metaOpts);
    % should not work
    success = 0;
catch
    success = success*1;
end

end