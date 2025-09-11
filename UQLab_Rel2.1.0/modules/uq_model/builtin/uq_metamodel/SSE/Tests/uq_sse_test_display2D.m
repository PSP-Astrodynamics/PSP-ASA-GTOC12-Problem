function [success] = uq_sse_test_display2D(level)
% UQ_SSE_TEST_DISPLAY2D
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
metaOpts.Refine.NExp = 10;

% Experimental design
metaOpts.ExpDesign.Sampling = 'Sequential';
metaOpts.ExpDesign.NSamples = 40;

%% CREATE SSE
mySSE = uq_createModel(metaOpts);

%% TEST some things
try
  % test display function
  H = uq_display(mySSE, 1, 'partitionQuantile', inf);
  close(H{:})
  H = uq_display(mySSE, 'partitionPhysical', inf);
  close(H{:})
  H = uq_display(mySSE, 'refineScore', inf);
  close(H{:})
  H = uq_display(mySSE, 'errorEvolution', true);
  close(H{:})
  H = uq_display(mySSE, 'plotGraph', inf);
  close(H{:})
  success = 1;
catch
  success = 0;
end