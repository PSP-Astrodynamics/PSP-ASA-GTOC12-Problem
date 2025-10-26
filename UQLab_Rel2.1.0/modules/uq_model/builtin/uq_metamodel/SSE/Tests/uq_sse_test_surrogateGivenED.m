function [success] = uq_sse_test_surrogateGivenED(level)
% UQ_SSE_TEST_SURROGATEGIVENED 
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
% number of total model evaluations
metaOpts.ExpOptions.TruncOptions.MaxInteraction = 2;
metaOpts.ExpOptions.TruncOptions.qNorm = 0.5:0.1:0.8;
metaOpts.ExpOptions.Degree = 0:4;
% maximum refinement steps
maxRefine = 4;
metaOpts.Stopping.MaxRefine = maxRefine;

% Experimental design
metaOpts.ExpDesign.X = uq_getSample(myInput,100);
metaOpts.ExpDesign.Y = uq_evalModel(myModel,metaOpts.ExpDesign.X);
% Validation
metaOpts.ValidationSet.X = uq_getSample(myInput,1e3);
metaOpts.ValidationSet.Y = uq_evalModel(metaOpts.ValidationSet.X);


%% CREATE SSE
mySSE = uq_createModel(metaOpts);

%% TEST some things
try
  X = uq_getSample(1e3);
  YSSE_1 = uq_evalModel(mySSE,X,'maxRefine',1);
  YSSE = uq_evalModel(mySSE,X);
  Y = uq_evalModel(myModel,X);
  
  uq_print(mySSE)
  
  % check that maxRefine refinement steps were done
  if mySSE.SSE.currRef ~= maxRefine
      error('Refinement did not stop after %d refinemet steps', maxRefine)
  end
  success = 1;
catch
  success = 0;
end