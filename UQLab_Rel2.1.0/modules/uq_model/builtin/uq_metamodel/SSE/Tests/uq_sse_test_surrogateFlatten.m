function [success] = uq_sse_test_surrogateFlatten(level)
% UQ_SSE_TEST_SURROGATEADAPTIVEED 
%
%   See also: UQ_SELFTEST_UQ_SSE

%% START UQLAB
uqlab('-nosplash');

if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| ',mfilename,'...\n']);

%% PROBLEM SETUP
%% Specify the input and the model
Iopts.Marginals(1).Name = 'P' ;
Iopts.Marginals(1).Type = 'Gumbel' ;
Iopts.Marginals(1).Moments = [430 0.2*430] ;

Iopts.Marginals(2).Name = 'E' ;
Iopts.Marginals(2).Type = 'Lognormal' ;
Iopts.Marginals(2).Moments = [210e6 210e5] ;

Iopts.Marginals(3).Name = 'A' ;
Iopts.Marginals(3).Type = 'Gaussian' ;
Iopts.Marginals(3).Moments = [1e-3 0.05*1e-3] ;

myInput = uq_createInput(Iopts) ;
clear Iopts;

mOpts.mFile = 'uq_SnapThroughTruss';
myModel = uq_createModel(mOpts);
clear mOpts;

% make third input marginal constant
inputOpts = myInput.Options;
inputOpts.Marginals(3).Type = 'Constant';
inputOpts.Marginals(3).Moments = inputOpts.Marginals(3).Moments(1);
myInput = uq_createInput(inputOpts);

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

% Flatten SSE
metaOpts.PostProcessing.Flatten = true;

% Experimental design
metaOpts.ExpDesign.Sampling = 'Sequential';
metaOpts.ExpDesign.NSamples = 1e2;

%% CREATE SSE
mySSE = uq_createModel(metaOpts);

%% TEST some things
try
  X = uq_getSample(1e3);
  YSSE_flat = uq_evalModel(mySSE,X);
  mySSE.SSE.FlatGraph = digraph();
  YSSE = uq_evalModel(mySSE,X);
  
  % check if flat SSE deviates considerably from deep SSE
  thresh = 1e-10;
  if mean(abs(YSSE-YSSE_flat)) > thresh
      error('Flattened SSE deviates from deep SSE!')
  end
  
  uq_print(mySSE)
  success = 1;
catch
  success = 0;
end