function [success] = uq_sse_test_display1D(level)
% UQ_SSE_TEST_DISPLAY1D
%
%   See also: UQ_SELFTEST_UQ_SSE

%% START UQLAB
uqlab('-nosplash');

if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| ',mfilename,'...\n']);

%% PROBLEM SETUP

%% PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of a uniform random variable:

%%
% Specify the probabilistic model of the input variable:
IOpts.Marginals.Type = 'Uniform';
IOpts.Marginals.Parameters = [0 1];

% Create an INPUT object:
myInput = uq_createInput(IOpts);
clear IOpts;

%% COMPUTATIONAL MODEL
%
% complex-FUNCTION 
%
MOpts.mFile = 'uq_complexFunction';
MOpts.isVectorized = true;
myModel = uq_createModel(MOpts);
clear MOpts;

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
  H = uq_display(mySSE, 1, 'partitionPhysical', inf);
  close(H{:})
  H = uq_display(mySSE, 'refineScore', true);
  close(H{:})
  H = uq_display(mySSE, 'errorEvolution', true);
  close(H{:})
  H = uq_display(mySSE, 'plotGraph', inf);
  close(H{:})
  H = uq_display(mySSE, 'plotGraph', 2);
  close(H{:})
  success = 1;
catch
  success = 0;
end