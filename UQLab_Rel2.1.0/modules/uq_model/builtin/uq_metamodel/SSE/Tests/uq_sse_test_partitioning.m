function [success] = uq_sse_test_partitioning(level)
% UQ_SSE_TEST_PARTITIONING
%
%   See also: UQ_SELFTEST_UQ_SSE

%% START UQLAB
uqlab('-nosplash');

if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| ',mfilename,'...\n']);

%% PROBLEM SETUP
inputOpts.Copula = uq_PairCopula('Gumbel',1.5);
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
metaOpts.ExpOptions.Degree = 0:4;
% maximum polynomial degree
metaOpts.Refine.NExp = 5;
% partitioning
metaOpts.Partitioning = @(obj, subIdx) uq_SSE_partitioning_varDiff(obj, subIdx);

% provide a validation set
metaOpts.ValidationSet.X = uq_getSample(1e3);
metaOpts.ValidationSet.Y = uq_evalModel(metaOpts.ValidationSet.X);

% Experimental design
metaOpts.ExpDesign.Sampling = 'Sequential';
metaOpts.ExpDesign.NSamples = 40;

%% CREATE SSE
mySSE = uq_createModel(metaOpts);

%% TEST some things
try
  % check if handle was assigned properly
  functionHandleInfo = functions(mySSE.SSE.Partitioning);
  if ~strcmpi(functionHandleInfo.function, '@(obj,subIdx)uq_SSE_partitioning_varDiff(obj,subIdx)')
      error('Partitioning function handle not assigned properly')
  end
  
  % check that partitioning works
  outGoing = outdegree(mySSE.SSE.Graph);
  if ~(sum(mySSE.SSE.Graph.Nodes.inputMass(outGoing==0)) == 1)
      error('Terminal domains do not cover full input space!')
  end
  
  uq_print(mySSE)
  success = 1;
catch
  success = 0;
end