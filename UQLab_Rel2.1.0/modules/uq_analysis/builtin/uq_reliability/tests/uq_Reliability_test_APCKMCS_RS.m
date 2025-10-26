function success = uq_Reliability_test_APCKMCS_RS(level)
% SUCCESS = UQ_RELIABILITY_TEST_APCKMCS_RS(LEVEL):
%     Comparing the results of APCKMCS to the analytical failure
%     probabilities. And checking for some other properties of APCK-MCS.
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
M = 5;
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
%PFAnalytic = cdf('normal', -M/sqrt(M), 0, 1);
PFReference = 0.01900;
BetaAnalytic = M/sqrt(M);


%% APCK-MCS
rng(seed)
akopts.Type = 'Reliability';
akopts.Method = 'AKMCS';
akopts.Simulation.BatchSize = 1e3;
akopts.Simulation.MaxSampleSize = 1e3;
akopts.AKMCS.MaxAddedED = 10;
akopts.AKMCS.MetaModel = 'PCK';
akopts.LimitState.Threshold = 0;
akopts.LimitState.CompOp = '<=';
akopts.Display = 'quiet';

AKAnalysis = uq_createAnalysis(akopts);
AKResults = AKAnalysis.Results;

%% check the results
success = 0;
switch false
    case isinthreshold(AKResults.Pf, PFReference, TH*PFReference)
        ErrMsg = sprintf('probability estimate.\nAPCKMCS   : %s\nAnalytic: %s', uq_sprintf_mat(AKResults.Pf), uq_sprintf_mat(PFReference));
    case isinthreshold(AKResults.Beta, BetaAnalytic, TH*BetaAnalytic)
        ErrMsg = sprintf('reliability index\nAPCKMCS    : %s\nAnalytic: %s', uq_sprintf_mat(AKResults.Beta), uq_sprintf_mat(BetaAnalytic));
    case AKAnalysis.Internal.Simulation.BatchSize == akopts.Simulation.BatchSize
        ErrMsg = sprintf('MC sample size\nAPCKMCS   : %s\nOptions: %s', uq_sprintf_mat(AKResults.MCSampleSize), uq_sprintf_mat(akopts.Simulation.BatchSize));
    otherwise
        success = 1;
end
if success == 0
    ErrStr = sprintf('\nError in uq_test_APCKMCS_RS while comparing the %s\n', ErrMsg);
    error(ErrStr);
end


function Res = isinthreshold(A, B, TH)
Res = max(abs(A(:) - B(:))) < TH;
