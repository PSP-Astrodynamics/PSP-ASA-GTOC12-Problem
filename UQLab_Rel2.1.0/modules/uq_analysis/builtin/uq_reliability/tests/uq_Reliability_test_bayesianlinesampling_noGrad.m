function success = uq_Reliability_test_bayesianlinesampling_noGrad(level)
% SUCCESS = UQ_RELIABILITY_TEST_BAYESIANLINESAMPLING_NOGRAD(LEVEL):
%     Test line sampline when gradient at origin is flat.
%
% See also UQ_SELFTEST_UQ_RELIABILITY

%% Start test:
uqlab('-nosplash');
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| ' mfilename '...\n']);


%% set a seed
seed = 42;
rng(seed)

%% create the input
IOpts.Marginals(1).Type = 'Gaussian';
IOpts.Marginals(1).Moments = [0 1];

IOpts.Marginals(2).Type = 'Gaussian';
IOpts.Marginals(2).Moments = [0 1];

% Create the input:
uq_createInput(IOpts);

%% create the computational model
MOpts.mString = '3 - X(:,1) .* X(:,2)';
MOpts.isVectorized = true;
uq_createModel(MOpts);

%% line sampling with polynomial
lsopts.Type = 'reliability';
lsopts.Method = 'bls';
lsopts.Simulation.BatchSize = 1000;
lsopts.Simulation.MaxSampleSize = 1000;
lsopts.BLS.MaxAddedEd = 1;

%% check the results
success = 0;
try
    uq_createAnalysis(lsopts);
    success = 1;
catch
    ErrStr = sprintf('\nError in uq_Reliability_test_bayesianlinesampling_noGrad\n');
    error(ErrStr)
end

