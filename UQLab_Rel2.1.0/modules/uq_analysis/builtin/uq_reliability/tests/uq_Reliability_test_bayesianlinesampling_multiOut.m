function success = uq_Reliability_test_bayesianlinesampling_multiOut(level)
% SUCCESS = UQ_RELIABILITY_TEST_BAYESIANLINESAMPLING_MULTIOUT(LEVEL):
%     Comparing the results of line sampling to the analytical faiure
%     probabilities for multiple outputs
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
rng(seed)

%% threshold for numerical imprecision
TH = 1e-2;

%% Create the model and input
% Model
MOpts.mHandle = @(X) [X(:,1) - X(:,2), 2*X(:,1) - X(:,2)];
MOpts.isVectorized = true;
testModel = uq_createModel(MOpts, '-private');

% Input
InputOpts.Marginals(1).Name = 'R';  % resistance variable
InputOpts.Marginals(1).Type = 'Gaussian';
InputOpts.Marginals(1).Moments = [5 0.8];

InputOpts.Marginals(2).Name = 'S';  % stress variable
InputOpts.Marginals(2).Type = 'Gaussian';
InputOpts.Marginals(2).Moments = [2 0.6];
testInput = uq_createInput(InputOpts, '-private');

% Expected common results:
Expected.Pf = [1.3499e-03, 1.4229e-06];

%% Line Sampling Options
lsopts.Type = 'reliability';
lsopts.Method = 'bls';

lsopts.LS.BatchSize = 1;
lsopts.LS.MaxLines = 5;
lsopts.Display = 0;

lsopts.Model = testModel;
lsopts.Input = testInput;

LSAnalysis = uq_createAnalysis(lsopts);
LSResults = LSAnalysis.Results;

%% check the results
[success, ErrMsg] = uq_compareStructs(Expected, LSResults, TH);

if success == 0
    fprintf('\n\n%s.', ErrMsg);
	fprintf('\n');
    error('\nError in uq_test_bayesianlinesampling_multiOut \n');
end

try
    uq_print(LSAnalysis,1:2)
catch
    success = 0;
    ErrStr = sprintf('\nError in uq_test_bayesianlinesampling_multiOut using uq_print\n');
    error(ErrStr)
end

try
    uq_display(LSAnalysis,1:2)
catch
    success = 0;
    ErrStr = sprintf('\nError in uq_test_bayesianlinesampling_multiOut using uq_display \n');
    error(ErrStr)
end



