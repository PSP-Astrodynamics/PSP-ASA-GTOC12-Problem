function success = uq_Reliability_test_bayesianlinesampling_inout(level)
% SUCCESS = UQ_RELIABILITY_TEST_BAYESIANLINESAMPLING_INOUT(LEVEL):
%    Test function to check whether the input arguments are correctly 
%    passed to the output structure on a simple R-S example
%
% See also UQ_SELFTEST_UQ_RELIABILITY


%% Start test:
uqlab('-nosplash');
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| ' mfilename '...\n']);


%% set a seed
seed = 1;

%% create an input
M = 2;
for ii = 1:M
    IOpts.Marginals(ii).Name = 'R';
    IOpts.Marginals(ii).Type = 'Gaussian';
    IOpts.Marginals(ii).Moments = [1 1];
end

% Create the input:
uq_createInput(IOpts);

%% create a computational model
rng(seed)
MOpts.mString = 'sum(X,2)';
MOpts.isVectorized = true;
uq_createModel(MOpts);

%% create a subset simulation where all options are non-default
BLSOptions.Type = 'Reliability';
BLSOptions.Method = 'BLS';

BLSOptions.Simulation.BatchSize = 23;
BLSOptions.Simulation.MaxSampleSize = 2300;
BLSOptions.Simulation.Alpha = 0.1;

BLSOptions.LimitState.Threshold = 5;
BLSOptions.LimitState.CompOp = '>';

BLSOptions.BLS.LearningFunction = 'upper variance';

BLSOptions.BLS.IExpDesign.N = 5;
BLSOptions.BLS.IExpDesign.Sampling = 'sobol';

BLSOptions.BLS.MaxAddedED = 10;

BLSOptions.BLS.ConvCoV = 0.05;

BLSOptions.BLS.Kriging.Trend.Type = 'linear';
BLSOptions.BLS.Kriging.Corr.Family = 'Matern-3_2';

BLSOptions.Display = 0;
BLSOptions.SaveEvaluations = 1;

myBLS = uq_createAnalysis(BLSOptions);
IntBLS = myBLS.Internal;
History = myBLS.Results.History;

%% check the response structure
crit = [ 
         %check whether the correct options were passed
         strcmp(IntBLS.Input.Name, 'Input 1') 
         IntBLS.Simulation.BatchSize == BLSOptions.Simulation.BatchSize
         IntBLS.Simulation.MaxSampleSize == BLSOptions.Simulation.MaxSampleSize
         IntBLS.Simulation.Alpha == BLSOptions.Simulation.Alpha
         IntBLS.LimitState.Threshold == BLSOptions.LimitState.Threshold
         IntBLS.LimitState.CompOp == BLSOptions.LimitState.CompOp
         strcmp(IntBLS.BLS.LearningFunction, BLSOptions.BLS.LearningFunction)
         IntBLS.BLS.IExpDesign.N == BLSOptions.BLS.IExpDesign.N
         strcmp(IntBLS.BLS.IExpDesign.Sampling, BLSOptions.BLS.IExpDesign.Sampling)
         IntBLS.BLS.MaxAddedED == BLSOptions.BLS.MaxAddedED
         IntBLS.BLS.ConvCoV == BLSOptions.BLS.ConvCoV
         strcmp(IntBLS.BLS.Kriging.Trend.Type, BLSOptions.BLS.Kriging.Trend.Type)
         strcmp(IntBLS.BLS.Kriging.Corr.Family, BLSOptions.BLS.Kriging.Corr.Family)
         IntBLS.Display == BLSOptions.Display
         IntBLS.SaveEvaluations == BLSOptions.SaveEvaluations

         
         %check some statistics on the response
         length(History.Pf) == length(History.Conf)
         size(History.X(1),1) == size(History.U(1),1)
         
         ];
if sum(crit == 0) == 0
     success = 1;
     fprintf('\nTest uq_test_bayesianlinesampling_inout finished successfully!\n');
else
    ErrStr = 'Error in uq_test_bayesianlinesampling_inout while comparing the input and output structures';
    error(ErrStr);
end