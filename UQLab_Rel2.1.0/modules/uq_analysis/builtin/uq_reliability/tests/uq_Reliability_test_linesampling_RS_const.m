function success = uq_Reliability_test_linesampling_RS_const(level)
% SUCCESS = UQ_RELIABILITY_TEST_linesampling_RS(LEVEL):
%     Comparing the results of line sampling to the analytical faiure
%     probabilities.
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
M = 7;
Mnonconst = 5;
for ii = 1:M
    IOpts.Marginals(ii).Name = 'R';
    IOpts.Marginals(ii).Type = 'Gaussian';
    IOpts.Marginals(ii).Moments = [1 1];
end
IOpts.Marginals(5).Name = 'irrelevant';
IOpts.Marginals(5).Type = 'constant';
IOpts.Marginals(5).Moments = [0 0];

IOpts.Marginals(7).Name = 'irrelevant';
IOpts.Marginals(7).Type = 'Constant';
IOpts.Marginals(7).Moments = [1 0];


% Create the input:
uq_createInput(IOpts);

%% create the computational model
MOpts.mString = 'sum(X(:,[1 2 3 4 6]),2).*X(:,7) + X(:,5)';
MOpts.isVectorized = true;
uq_createModel(MOpts);

%% analytical failure probability and reliabiltiy index
%PFAnalytic = cdf('normal', -M/sqrt(M), 0, 1);
PFRef = 0.0127;
BetaRef = Mnonconst/sqrt(Mnonconst);


%% subset simulation
lsopts.Type = 'reliability';
lsopts.Method = 'ls';
lsopts.LS.BatchSize = 50;
lsopts.LS.MaxLines = 50;
lsopts.LimitState.Threshold = 0;
lsopts.LimitState.CompOp = '<=';

lsopts.Display = 0;

LSAnalysis = uq_createAnalysis(lsopts, '-private');
LSResults = LSAnalysis.Results;

%% check the results
success = 0;
switch false
    case isinthreshold(LSResults.Pf, PFRef, TH*PFRef)
        ErrMsg = sprintf('probability estimate.\nLS: %s\nAnalytic: %s', uq_sprintf_mat(LSResults.Pf), uq_sprintf_mat(PFRef));
    case isinthreshold(LSResults.Beta, BetaRef, TH*BetaRef)
        ErrMsg = sprintf('reliability index\nLS: %s\nAnalytic: %s', uq_sprintf_mat(LSResults.Beta), uq_sprintf_mat(BetaRef));
    otherwise
        success = 1;
        fprintf('\nTest uq_test_linesampling_RS finished successfully!\n');
end
if success == 0
    ErrStr = sprintf('\nError in uq_test_linesampling_RS while comparing the %s\n', ErrMsg);
    error(ErrStr);
end

function Res = isinthreshold(A, B, TH)
Res = max(abs(A(:) - B(:))) < TH;


