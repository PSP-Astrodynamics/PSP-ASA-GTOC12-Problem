function success = uq_Reliability_test_AKMCS_RS_constant(level)
% SUCCESS = UQ_RELIABILITY_TEST_AKMCS_RS_CONSTANT(LEVEL)
%     Comparing the results of AKMCS to the analytical failure
%     probabilities. And checking for some other properties of AK-MCS. Two
%     variables are set to be constant
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

%% analytical failure probability
%PFAnalytic = cdf('normal', -M/sqrt(M), 0, 1);
PFReference = 0.01900;
BetaAnalytic = Mnonconst/sqrt(Mnonconst);


%% AK-MCS
rng(seed)
akopts.Type = 'Reliability';
akopts.Method = 'AKMCS';
akopts.Simulation.BatchSize = 1e3;
akopts.Simulation.MaxSampleSize = 1e3;
akopts.AKMCS.MaxAddedED = 10;
akopts.LimitState.Threshold = 0;
akopts.LimitState.CompOp = '<=';
akopts.Display = 'quiet';

AKAnalysis = uq_createAnalysis(akopts, '-private');
AKResults = AKAnalysis.Results;

%% check the results
success = 0;
switch false
    case isinthreshold(AKResults.Pf, PFReference, TH*PFReference)
        ErrMsg = sprintf('probability estimate.\nAKMCS   : %s\nAnalytic: %s', uq_sprintf_mat(AKResults.Pf), uq_sprintf_mat(PFReference));
    case isinthreshold(AKResults.Beta, BetaAnalytic, TH*BetaAnalytic)
        ErrMsg = sprintf('reliability index\nAKMCS    : %s\nAnalytic: %s', uq_sprintf_mat(AKResults.Beta), uq_sprintf_mat(BetaAnalytic));
    case AKAnalysis.Internal.Simulation.BatchSize == akopts.Simulation.BatchSize
        ErrMsg = sprintf('MC sample size\nAKMCS   : %s\nOptions: %s', uq_sprintf_mat(AKResults.MCSampleSize), uq_sprintf_mat(akopts.Simulation.BatchSize));
    otherwise
        success = 1;
end
if success == 0
    ErrStr = sprintf('\nError in uq_test_AKMCS_RS while comparing the %s\n', ErrMsg);
    error(ErrStr);
end


function Res = isinthreshold(A, B, TH)
Res = max(abs(A(:) - B(:))) < TH;
