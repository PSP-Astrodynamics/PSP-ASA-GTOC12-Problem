function success = uq_Reliability_test_bayesianlinesampling_RS(level)
% SUCCESS = UQ_RELIABILITY_TEST_BAYESIANLINESAMPLING_RS(LEVEL):
%     Comparing the results of Bayesian line sampling 
%     to the analytical faiure probabilities.
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

%% create the input
% Marginals:
M = 10;
for ii = 1:M
    IOpts.Marginals(ii).Name = 'R';
    IOpts.Marginals(ii).Type = 'Gaussian';
    IOpts.Marginals(ii).Moments = [1 1];
end

% Create the input:
uq_createInput(IOpts);

%% create the computational model
MOpts.mString = 'sum(X,2)';
MOpts.isVectorized = true;
uq_createModel(MOpts);

%% analytical failure probability and reliabiltiy index
BetaRef = 3.1623;
PFRef = 7.8270e-04;

%% subset simulation
lsopts.Type = 'reliability';
lsopts.Method = 'BLS';
lsopts.LimitState.Threshold = 0;
lsopts.LimitState.CompOp = '<=';

lsopts.Display = 0;

LSAnalysis = uq_createAnalysis(lsopts);
LSResults = LSAnalysis.Results;

%% check the results
success = 0;
switch false
    case isinthreshold(LSResults.Pf, PFRef, TH*PFRef)
        ErrMsg = sprintf('probability estimate.\nBLS: %s\nAnalytic: %s', uq_sprintf_mat(LSResults.Pf), uq_sprintf_mat(PFRef));
    case isinthreshold(LSResults.Beta, BetaRef, TH*BetaRef)
        ErrMsg = sprintf('reliability index\nBLS: %s\nAnalytic: %s', uq_sprintf_mat(LSResults.Beta), uq_sprintf_mat(BetaRef));
    otherwise
        success = 1;
        fprintf('\nTest uq_test_bls_RS finished successfully!\n');
end
if success == 0
    ErrStr = sprintf('\nError in uq_test_bls_RS while comparing the %s\n', ErrMsg);
    error(ErrStr);
end

try
    uq_print(LSAnalysis)
catch
    success = 0;
    ErrStr = sprintf('\nError in uq_test_bayesianlinesampling_RS using uq_print\n');
    error(ErrStr)
end

try
    uq_display(LSAnalysis)
catch
    success = 0;
    ErrStr = sprintf('\nError in uq_test_bayesianlinesampling_RS using uq_display\n');
    error(ErrStr)
end

function Res = isinthreshold(A, B, TH)
Res = max(abs(A(:) - B(:))) < TH;


