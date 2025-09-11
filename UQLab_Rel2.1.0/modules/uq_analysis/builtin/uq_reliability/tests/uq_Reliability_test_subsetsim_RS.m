function success = uq_Reliability_test_subsetsim_RS(level)
% SUCCESS = UQ_RELIABILITY_TEST_SUBSETSIM_RS(LEVEL):
%     Comparing the results of subset simulation to the analytical faiure
%     probabilities. We give a subset simulation with a large number of 
%     samples in each subset to ensure high accuracy
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

%% settings for subset simulation
p0 = 0.1;

%% analytical failure probability and reliabiltiy index
BetaRef = 3.10793;
PFRef = 0.00094;

%quantiles for intermetdiate thresholds
QuantileRef = [5.83278	 2.61342	 0.06430];

%% subset simulation
sopts.Type = 'reliability';
sopts.Method = 'Subset';
sopts.Simulation.BatchSize = 1e3;
sopts.Simulation.MaxSampleSize = 1e4;
sopts.LimitState.Threshold = 0;
sopts.LimitState.CompOp = '<=';
sopts.Subset.p0 = p0;
sopts.Subset.Proposal.Type = 'Gaussian';
sopts.Subset.Proposal.Parameters = 1;

sopts.Display = 0;

SSAnalysis = uq_createAnalysis(sopts);
SSResults = SSAnalysis.Results;

%% check the results
success = 0;
switch false
    case isinthreshold(SSResults.Pf, PFRef, TH*PFRef)
        ErrMsg = sprintf('probability estimate.\nSubsetSi: %s\nAnalytic: %s', uq_sprintf_mat(SSResults.Pf), uq_sprintf_mat(PFRef));
    case isinthreshold(SSResults.Beta, BetaRef, TH*BetaRef)
        ErrMsg = sprintf('reliability index\nSubsetSi: %s\nAnalytic: %s', uq_sprintf_mat(SSResults.Beta), uq_sprintf_mat(BetaRef));
    case isinthreshold(SSResults.History.q(1:end-1), QuantileRef, TH*sqrt(M))
        ErrMsg = sprintf('quantiles\nSubsetSi: %s\nAnalytic: %s', uq_sprintf_mat(SSResults.History.q(1:end-1)), uq_sprintf_mat(QuantileRef));
    otherwise
        success = 1;
        fprintf('\nTest uq_test_subsetsim_RS finished successfully!\n');
end
if success == 0
    ErrStr = sprintf('\nError in uq_test_subsetsim_RS while comparing the %s\n', ErrMsg);
    error(ErrStr);
end

function Res = isinthreshold(A, B, TH)
Res = max(abs(A(:) - B(:))) < TH;