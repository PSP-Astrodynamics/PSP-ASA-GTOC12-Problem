function success = uq_Reliability_test_ALR_RS_constant(level)
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
M = 5;
Mnonconst = 3;
for ii = 1:M
    IOpts.Marginals(ii).Name = 'R';
    IOpts.Marginals(ii).Type = 'Gaussian';
    IOpts.Marginals(ii).Moments = [1 1];
end
IOpts.Marginals(3).Name = 'irrelevant';
IOpts.Marginals(3).Type = 'constant';
IOpts.Marginals(3).Moments = [0 0];

IOpts.Marginals(5).Name = 'irrelevant';
IOpts.Marginals(5).Type = 'Constant';
IOpts.Marginals(5).Moments = [1 0];


% Create the input:
uq_createInput(IOpts);

%% create the computational model
MOpts.mString = 'sum(X(:,[1 2 4]),2).*X(:,5) + X(:,3)';
MOpts.isVectorized = true;
uq_createModel(MOpts);

%% analytical failure probability
PFAnalytic = cdf('normal', -Mnonconst/sqrt(Mnonconst), 0, 1);
BetaAnalytic = Mnonconst/sqrt(Mnonconst);


%% AK-MCS
rng(seed)
alropts.Type = 'Reliability';
alropts.Method = 'ALR';
alropts.ALR.Metamodel = 'Kriging' ;
alropts.ALR.MaxAddedED = 10;
alropts.LimitState.Threshold = 0;
alropts.LimitState.CompOp = '<=';
alropts.Display = 'quiet';

ALRAnalysis = uq_createAnalysis(alropts, '-private');
ALRResults = ALRAnalysis.Results;

%% check the results
success = 0;
switch false
    case isinthreshold(ALRResults.Pf, PFAnalytic, TH*PFAnalytic)
        ErrMsg = sprintf('probability estimate.\nAKMCS   : %s\nAnalytic: %s', uq_sprintf_mat(ALRResults.Pf), uq_sprintf_mat(PFReference));
    case isinthreshold(ALRResults.Beta, BetaAnalytic, TH*BetaAnalytic)
        ErrMsg = sprintf('reliability index\nAKMCS    : %s\nAnalytic: %s', uq_sprintf_mat(ALRResults.Beta), uq_sprintf_mat(BetaAnalytic));
    otherwise
        success = 1;
end
if success == 0
    ErrStr = sprintf('\nError in uq_test_ALR_RS while comparing the %s\n', ErrMsg);
    error(ErrStr);
end


function Res = isinthreshold(A, B, TH)
Res = max(abs(A(:) - B(:))) < TH;
