function success = uq_Reliability_test_linesampling_inout(level)
% SUCCESS = UQ_RELIABILITY_TEST_LINESAMPLING_INOUT(LEVEL):
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
LSOpts.Type = 'Reliability';
LSOpts.Method = 'LS';

LSOpts.LimitState.Threshold = 5;
LSOpts.LimitState.CompOp = '>';

LSOpts.Simulation.Alpha = 0.1;

LSOpts.LS.BatchSize = 50;
LSOpts.LS.MaxLines = 50;
LSOpts.LS.TargetCoV = 0.1;

LSOpts.LS.RootFinder.Type = 'spline';
LSOpts.LS.RootFinder.WayPoints = 1:8;

LSOpts.LS.Direction.Initial = 'GradOrigin';
LSOpts.LS.Direction.Adaptive = false;

LSOpts.FORM.MaxIterations = 3;

LSOpts.Display = 0;
LSOpts.SaveEvaluations = 1;

myLS = uq_createAnalysis(LSOpts);
IntLS = myLS.Internal;
History = myLS.Results.History;

%% check the response structure
crit = [ 
         %check whether the correct options were passed
         strcmp(IntLS.Input.Name, 'Input 1') 
         IntLS.LimitState.Threshold == LSOpts.LimitState.Threshold
         IntLS.LimitState.CompOp == LSOpts.LimitState.CompOp
         IntLS.Simulation.Alpha == LSOpts.Simulation.Alpha
            
         IntLS.Simulation.BatchSize == LSOpts.LS.BatchSize
         IntLS.Simulation.MaxSampleSize == LSOpts.LS.MaxLines
         IntLS.Simulation.TargetCoV == LSOpts.LS.TargetCoV

         strcmp(IntLS.LS.RootFinder.Type , LSOpts.LS.RootFinder.Type)
         all(IntLS.LS.RootFinder.WayPoints == LSOpts.LS.RootFinder.WayPoints)

         strcmp(IntLS.LS.Direction.Initial, LSOpts.LS.Direction.Initial)
         IntLS.LS.Direction.Adaptive == LSOpts.LS.Direction.Adaptive
         IntLS.FORM.MaxIterations == LSOpts.FORM.MaxIterations

         IntLS.Display == LSOpts.Display
         IntLS.SaveEvaluations == LSOpts.SaveEvaluations
         
         %check some statistics on the response
         length(History.Pf) == length(History.Conf)
         size(History.X(1),1) == size(History.U(1),1)
         size(History.LineData.Intersects,1) == myLS.Results.Lines
         
         ];
if sum(crit == 0) == 0
     success = 1;
     fprintf('\nTest uq_test_linesampling_inout finished successfully!\n');
else
    ErrStr = 'Error in uq_test_linesampling_inout while comparing the input and output structures';
    error(ErrStr);
end