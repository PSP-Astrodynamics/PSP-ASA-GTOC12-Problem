function success = uq_Reliability_test_bayesianlinesampling_RS_const(level)
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
Rmean = 10;
Rstd = 1;
Smean = 4;
Sstd = 1;

%input marginals
IOpts.Marginals(1).Name = 'R';
IOpts.Marginals(1).Type = 'Gaussian';
IOpts.Marginals(1).Moments = [Rmean Rstd];

IOpts.Marginals(2).Name = 'S';
IOpts.Marginals(2).Type = 'Gaussian';
IOpts.Marginals(2).Moments = [Smean Sstd];

IOpts.Marginals(3).Name = 'irrelevant';
IOpts.Marginals(3).Type = 'constant';
IOpts.Marginals(3).Moments = 1;
% Create the input:
uq_createInput(IOpts);

%% create the computational model
MOpts.mString = '(X(:, 1) - X(:, 2)) .* X(:,3)';
MOpts.isVectorized = true;
uq_createModel(MOpts);

%% analytical failure probability and reliabiltiy index
BetaRef = (Rmean-Smean)/sqrt(Rstd^2 + Sstd^2);
PFRef = uq_gaussian_cdf(-BetaRef,[0 1]);

%% subset simulation
lsopts.Type = 'reliability';
lsopts.Method = 'bls';
lsopts.LimitState.Threshold = 0;
lsopts.LimitState.CompOp = '<=';

LSAnalysis = uq_createAnalysis(lsopts, '-private');
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
        fprintf('\nTest uq_test_bayesianlinesampling_RS_const finished successfully!\n');
end
if success == 0
    ErrStr = sprintf('\nError in uq_test_bayesianlinesampling_RS_const while comparing the %s\n', ErrMsg);
    error(ErrStr);
end

function Res = isinthreshold(A, B, TH)
Res = max(abs(A(:) - B(:))) < TH;


