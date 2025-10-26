function [success] = uq_sse_test_surrogateSequentialED(level)
% UQ_SSE_TEST_SURROGATESEQUENTIALED 
%
%   See also: UQ_SELFTEST_UQ_SSE

%% START UQLAB
uqlab('-nosplash');

if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| ',mfilename,'...\n']);

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

%% SSE Options
metaOpts.Type = 'metamodel';
metaOpts.MetaType = 'SSE';
metaOpts.Input = myInput;
% metaOpts.FullModel = myModel;
% number of total model evaluations
metaOpts.ExpOptions.TruncOptions.MaxInteraction = 2;
metaOpts.ExpOptions.TruncOptions.qNorm = 0.5:0.1:0.8;
metaOpts.ExpOptions.Degree = 0:2;
% maximum polynomial degree
metaOpts.Refine.NExp = 10;
% post processing
metaOpts.PostProcessing.OutputMoments = true;

% provide a validation set
metaOpts.ValidationSet.X = uq_getSample(1e3);
metaOpts.ValidationSet.Y = uq_evalModel(metaOpts.ValidationSet.X);

% Experimental design
metaOpts.ExpDesign.Sampling = 'Sequential';
metaOpts.ExpDesign.NSamples = 1e2;

%% CREATE SSE
mySSE = uq_createModel(metaOpts);

%% TEST some things
try
  X = uq_getSample(1e4);
  YSSE_1 = uq_evalModel(mySSE,X,'maxRefine',1);
  YSSE = uq_evalModel(mySSE,X);
  Y = uq_evalModel(myModel,X);
  meanMC = mean(Y);
  varMC = var(Y);
  meanSSE = mySSE.SSE.Moments.Mean;
  varSSE = mySSE.SSE.Moments.Var;
  
  % check whether output moments are correct
  admissError = 0.1;
  if max((meanMC-meanSSE)^2,abs(varMC-varSSE))/varMC > admissError
      error('Output moments are wrong!')
  end
  
  uq_print(mySSE)
  success = 1;
catch
  success = 0;
end