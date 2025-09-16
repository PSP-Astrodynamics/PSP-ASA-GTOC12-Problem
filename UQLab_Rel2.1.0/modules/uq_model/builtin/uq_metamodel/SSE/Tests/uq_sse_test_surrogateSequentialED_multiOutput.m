function [success] = uq_sse_test_surrogateSequentialED_multiOutput(level)
% UQ_SSE_TEST_SURROGATESEQUENTIALED_MULTIOUTPUT 
%
%   See also: UQ_SELFTEST_UQ_SSE

%% START UQLAB
uqlab('-nosplash');

if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| ',mfilename,'...\n']);

%% PROBLEM SETUP
%% 2 - COMPUTATIONAL MODEL
% The computational model is an analytical formula that is used to model
% the water flow through a borehole
% (http://www.sfu.ca/~ssurjano/borehole.html). 
% It is an 8-dimensional model.
%
% Create a model from the uq_borehole.m file
MOpts.mFile = 'uq_SimpleMultipleOutput';
myModel = uq_createModel(MOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%  Create the 2-dimensional stochastic input model.

IOpts.Marginals(1).Type = 'Gaussian';
IOpts.Marginals(1).Parameters = [0 1];

IOpts.Marginals(2).Type = 'Gaussian';
IOpts.Marginals(2).Parameters = [0 1];

%%
% Create and store the input object in UQLab
myInput = uq_createInput(IOpts);



%% SSE Options
metaOpts.Type = 'metamodel';
metaOpts.MetaType = 'SSE';
metaOpts.Input = myInput;
% number of total model evaluations
metaOpts.ExpOptions.TruncOptions.MaxInteraction = 2;
metaOpts.ExpOptions.TruncOptions.qNorm = 0.5:0.1:0.8;
metaOpts.ExpOptions.Degree = 0:4;
% maximum polynomial degree
metaOpts.Refine.NExp = 5;

% Explicitly assign full model
metaOpts.FullModel = myModel;

% Experimental design
metaOpts.ExpDesign.Sampling = 'Sequential';
metaOpts.ExpDesign.NSamples = 1e2;

try
  % CREATE SSE, should not work!
  mySSE = uq_createModel(metaOpts);
  success = 0;
catch
  success = 1;
end