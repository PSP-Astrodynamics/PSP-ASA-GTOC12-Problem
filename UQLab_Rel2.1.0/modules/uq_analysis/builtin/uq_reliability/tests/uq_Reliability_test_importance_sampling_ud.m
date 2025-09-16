function success = uq_Reliability_test_importance_sampling_ud(level)
% SUCCESS = UQ_RELIABILITY_TEST_IMPORTANCE_SAMPLING_UD(LEVEL):
%     This test solves a structural reliability problem both with Monte Carlo
%     and Importance Sampling. For IS, a user defined instrumental distribution
%     is given, that is exactly the same as the input distribution. Therefore,
%     the Monte Carlo and the Importance Sampling routines should give exactly
%     the same results.

success = 1;

%% Start test:
uqlab('-nosplash');
if nargin < 1
    level = 'normal'; 
end
fprintf(['\nRunning: |' level '| ' mfilename '...\n']);


%% Main parameters of the test itself:
% Randomly choose a random seed. It will be fixed later to ensure that 
% Monte Carlo and Importance Sampling coindice:
Seed = round(rand*100); 

% The CoV is not computed in the same way, so it might be a bit different
% due to numerical imprecision, we compare it within a threshold:
TH = 1e-3;

% Simulation Options (Shared by MC and IS):
SimOpts.Sampling = 'mc';
SimOpts.MaxSampleSize = 1e3;
SimOpts.BatchSize = 1e3;
SimOpts.Alpha = 0.05;

% LimitState (we lower a bit the requirements, so it converges faster)
LimitState.Threshold = 5;

% Generate a struct with the basic shared options between the methods:
BaseOpts.Type = 'Reliability';
BaseOpts.LimitState = LimitState;
BaseOpts.Simulation = SimOpts;
BaseOpts.SaveEvaluations = true;
BaseOpts.Display = 'nothing';

%% Define the model:
MOpts.mString = 'X(:, 1) - X(:, 2)';
MOpts.isVectorized = true;
myModel = uq_createModel(MOpts);

%% Create a source input:
% Moments:
mu_R = 7;
sigma_R = 0.5;

mu_S = 1;
sigma_S = 0.5;

% Marginals:
IOpts.Marginals(1).Name = 'R';
IOpts.Marginals(1).Type = 'lognormal';
IOpts.Marginals(1).Moments = [mu_R sigma_R];

IOpts.Marginals(2).Name = 'S';
IOpts.Marginals(2).Type = 'lognormal';
IOpts.Marginals(2).Moments = [mu_S sigma_S];

% Copula definition:
Rho = 0.52523;
IOpts.Copula.Type = 'Gaussian';
IOpts.Copula.Parameters = [1, Rho; Rho, 1];

% Create the input:
myInput = uq_createInput(IOpts);


%% Create the Monte Carlo analysis:
MCOpts = BaseOpts;
MCOpts.Method = 'MC';

rng(Seed)
MCAnalysis = uq_createAnalysis(MCOpts);

MCResults = MCAnalysis.Results;

%% Create the Importance Sampling analysis:
ISOpts = BaseOpts;

ISOpts.Method = 'IS';

% The instrumental density is the same as the original one:
ISOpts.IS.Instrumental = myInput;

rng(Seed);
ISAnalysis = uq_createAnalysis(ISOpts);
ISResults = ISAnalysis.Results;

%% Test the results:
success = 0;
switch false
    case isinthreshold(MCResults.Pf, ISResults.Pf, TH)
        ErrMsg = sprintf('probability estimate.\nMC: %s\nIS: %s', uq_sprintf_mat(MCResults.Pf), uq_sprintf_mat(ISResults.Pf));
        
    case isinthreshold(MCResults.Beta, ISResults.Beta, TH)
        ErrMsg = sprintf('reliability index\nMC: %s\nIS: %s', uq_sprintf_mat(MCResults.Beta), uq_sprintf_mat(ISResults.Beta));
        
    case isinthreshold(MCResults.CoV, ISResults.CoV, TH)
        ErrMsg = sprintf('coefficient of variation\nMC: %s\nIS: %s', uq_sprintf_mat(MCResults.CoV), uq_sprintf_mat(ISResults.CoV));
        
    case isinthreshold(MCResults.PfCI, ISResults.PfCI, TH)
        ErrMsg = sprintf('probability estimate confidence interval\nMC: %s\nIS: %s', uq_sprintf_mat(MCResults.PfCI), uq_sprintf_mat(ISResults.PfCI));
        
    case isinthreshold(MCResults.BetaCI, ISResults.BetaCI, TH)
        ErrMsg = sprintf('reliability index confidence interval\nMC: %s\nIS: %s', uq_sprintf_mat(MCResults.BetaCI), uq_sprintf_mat(ISResults.BetaCI));
        
    case isequal(MCResults.ModelEvaluations, ISResults.ModelEvaluations)
        ErrMsg = sprintf('number of evaluations\nMC: %s\nIS: %s', uq_sprintf_mat(MCResults.ModelEvaluations), uq_sprintf_mat(ISResults.ModelEvaluations));
        
        
    otherwise
        success = 1;
end
if success == 0
    ErrStr = sprintf('\nError in uq_test_importance_sampling_ud while comparing the %s\n', ErrMsg);
    error(ErrStr);
end


function Res = isinthreshold(A, B, TH)
Res = max(abs(A(:) - B(:))) < TH;