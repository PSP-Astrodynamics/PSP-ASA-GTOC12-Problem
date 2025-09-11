function success = uq_Reliability_test_subsetsim_inout(level)
% SUCCESS = UQ_RELIABILITY_TEST_SUBSETSIM_INOUT(LEVEL):
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
sopts.Type = 'Reliability';
sopts.Method = 'Subset';

sopts.Simulation.BatchSize = 12345;
sopts.Simulation.MaxSampleSize = 123456789;
sopts.Simulation.Alpha = 0.1;

sopts.LimitState.Threshold = 5;
sopts.LimitState.CompOp = '>';

sopts.Subset.p0 = 0.2;
sopts.Subset.Componentwise = 0;
sopts.Subset.Proposal.Parameters = [0.5];
sopts.Subset.Proposal.Type = 'gaussian';

sopts.SaveEvaluations = 1;

mySS = uq_createAnalysis(sopts);
IntS = mySS.Internal;
History = mySS.Results.History;

%% check the response structure
crit = [ 
         %check whether the correct options were passed
         strcmp(IntS.Input.Name, 'Input 1') 
         IntS.Simulation.BatchSize == sopts.Simulation.BatchSize
         IntS.Simulation.MaxSampleSize == sopts.Simulation.MaxSampleSize
         IntS.LimitState.Threshold == sopts.LimitState.Threshold
         IntS.LimitState.CompOp == sopts.LimitState.CompOp
         IntS.Subset.p0 == sopts.Subset.p0
         IntS.Subset.Componentwise == sopts.Subset.Componentwise
         IntS.Subset.Proposal.Parameters(1) == sopts.Subset.Proposal.Parameters(1)
         strcmp(IntS.Subset.Proposal.Type, sopts.Subset.Proposal.Type)
         IntS.Subset.MaxSubsets == floor(sopts.Simulation.MaxSampleSize / sopts.Simulation.BatchSize / (1-sopts.Subset.p0))
         
         %check some statistics on the response
         length(History.q) == length(History.delta2)
         length(History.Pfcond) == length(History.q)
         length(History.gamma) == length(History.Pfcond)
         size(History.X(1),1) == size(History.U(1),1)
         
         ];
if sum(crit == 0) == 0
     success = 1;
     fprintf('\nTest uq_test_subsetsim_inout finished successfully!\n');
else
    ErrStr = 'Error in uq_test_subsetsim_inout while comparing the input and output structures';
    error(ErrStr);
end