function [success] = uq_sse_test_surrogateGivenED_multiOutput(level)
% UQ_SSE_TEST_SURROGATEGIVENED_MULTIOUTPUT
%
%   See also: UQ_SELFTEST_UQ_SSE

%% START UQLAB
uqlab('-nosplash');

if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| ',mfilename,'...\n']);

%% PROBLEM SETUP
for ii = 1:3
    Input.Marginals(ii).Type = 'Uniform' ;
    Input.Marginals(ii).Parameters = [-pi, pi] ;
end

myInput = uq_createInput(Input);

modelopts.Name = 'ishigami multiout test';
modelopts.mFile = 'uq_ishigami_various_outputs' ;
myModel = uq_createModel(modelopts);

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

% Experimental design
metaOpts.ExpDesign.Sampling = 'LHS';
metaOpts.ExpDesign.NSamples = 100;

%% CREATE SSE
mySSE = uq_createModel(metaOpts);

%% TEST some things
try
  X = uq_getSample(1e3);
  YSSE_1 = uq_evalModel(mySSE,X,'maxRefine',1);
  YSSE_2 = uq_evalModel(mySSE,X(:,2),'varDim',2);
  YSSE = uq_evalModel(mySSE,X);
  Y = uq_evalModel(myModel,X);
  
  uq_print(mySSE,1)
  success = 1;
catch
  success = 0;
end