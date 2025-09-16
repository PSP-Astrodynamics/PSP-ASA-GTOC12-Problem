function success = uq_Reliability_test_ALR_RS(level)
% SUCCESS = UQ_RELIABILITY_TEST_ALR_RS(LEVEL):
%     Comparing the results of ALR to the analytical failure
%     probabilities. And checking for some other properties of ALR.
%  
% See also: UQ_SELFTEST_UQ_RELIABILITY

%% Start test:
uqlab('-nosplash');

if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| ' mfilename '...\n']);


%% set a seed
seed = 1;


%% threshold for numerical imprecision
TH = 1e-1;

%% create the input
% Marginals:
M = 3;
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

%% analytical failure probability
PFAnalytic = cdf('normal', -M/sqrt(M), 0, 1);
BetaAnalytic = M/sqrt(M);


%% ALR-MCS
rng(seed)
alropts.Type = 'Reliability';
alropts.Method = 'ALR';
alropts.ALR.MaxAddedED = 10;
alropts.LimitState.Threshold = 0;
alropts.LimitState.CompOp = '<=';
alropts.Display = 'quiet';

ALRAnalysis = uq_createAnalysis(alropts);
ALRResults = ALRAnalysis.Results;

%% check the results
success = 0;
switch false
    case isinthreshold(ALRResults.Pf, PFAnalytic, TH*PFAnalytic)
        ErrMsg = sprintf('probability estimate.\nALRMCS   : %s\nAnalytic: %s', uq_sprintf_mat(ALRResults.Pf), uq_sprintf_mat(PFReference));
    case isinthreshold(ALRResults.Beta, BetaAnalytic, TH*BetaAnalytic)
        ErrMsg = sprintf('reliability index\nALRMCS    : %s\nAnalytic: %s', uq_sprintf_mat(ALRResults.Beta), uq_sprintf_mat(BetaAnalytic));
    otherwise
        success = 1;
end
if success == 0
    ErrStr = sprintf('\nError in uq_test_ALR_RS while comparing the %s\n', ErrMsg);
    error(ErrStr);
end


function Res = isinthreshold(A, B, TH)
Res = max(abs(A(:) - B(:))) < TH;
