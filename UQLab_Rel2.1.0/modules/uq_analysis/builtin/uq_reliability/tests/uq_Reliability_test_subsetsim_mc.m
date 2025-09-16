function success = uq_Reliability_test_subsetsim_mc(level)
% SUCCESS = UQ_RELIABILITY_TEST_SUBSETSIM_MC(LEVEL):
%     This test checks whether the subset simulation returns exactly the same
%     value as Monte Carlo simulation in the case where the failure probability
%     is larger than p0=0.1;
%
% See also UQ_SELFTEST_UQ_RELIABILITY

%% Start test:
uqlab('-nosplash');
if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| ' mfilename '...\n']);



%% set a seed
seed = round(rand*100);


%% threshold for numerical imprecision
TH = 1e-8;


%% create the input
% Marginals:
IOpts.Marginals(1).Name = 'R';
IOpts.Marginals(1).Type = 'Gaussian';
IOpts.Marginals(1).Moments = [1 0.8];

IOpts.Marginals(2).Name = 'S';
IOpts.Marginals(2).Type = 'Gaussian';
IOpts.Marginals(2).Moments = [0 0.6];

% Copula definition:
Rho = 0.15;
IOpts.Copula.Type = 'Gaussian';
IOpts.Copula.Parameters = [1, Rho; Rho, 1];

% Create the input:
uq_createInput(IOpts);


%% create the model
MOpts.mString = 'X(:, 1) - X(:, 2)';
MOpts.isVectorized = true;
uq_createModel(MOpts);


%% MC analysis
mopts.Type = 'reliability';
mopts.Method = 'MC';
mopts.Simulation.BatchSize = 1e5;
mopts.Simulation.MaxSampleSize = 1e5;
mopts.LimitState.Threshold = 0;
mopts.LimitState.CompOp = '<=';

mopts.Display = 'quiet';

rng(seed)
myMC = uq_createAnalysis(mopts);
MCResults = myMC.Results;


%% subset simulation 
sopts = mopts;
sopts.Method = 'Subset';

rng(seed)
mySS = uq_createAnalysis(sopts);
SSResults = mySS.Results;


%% comparison
success = 0;
switch false
case isinthreshold(MCResults.Pf, SSResults.Pf, TH)
        ErrMsg = sprintf('probability estimate.\nMC: %s\nIS: %s', uq_sprintf_mat(MCResults.Pf), uq_sprintf_mat(SSResults.Pf));
        
    case isinthreshold(MCResults.Beta, SSResults.Beta, TH)
        ErrMsg = sprintf('reliability index\nMC: %s\nIS: %s', uq_sprintf_mat(MCResults.Beta), uq_sprintf_mat(SSResults.Beta));
        
    case isinthreshold(MCResults.CoV, SSResults.CoV, TH)
        ErrMsg = sprintf('coefficient of variation\nMC: %s\nIS: %s', uq_sprintf_mat(MCResults.CoV), uq_sprintf_mat(SSResults.CoV));
        
    case isinthreshold(MCResults.PfCI, SSResults.PfCI, TH)
        ErrMsg = sprintf('probability estimate confidence interval\nMC: %s\nIS: %s', uq_sprintf_mat(MCResults.PfCI), uq_sprintf_mat(SSResults.PfCI));
        
    case isinthreshold(MCResults.BetaCI, SSResults.BetaCI, TH)
        ErrMsg = sprintf('reliability index confidence interval\nMC: %s\nIS: %s', uq_sprintf_mat(MCResults.BetaCI), uq_sprintf_mat(SSResults.BetaCI));
        
    case isequal(MCResults.ModelEvaluations, SSResults.ModelEvaluations)
        ErrMsg = sprintf('number of evaluations\nMC: %s\nIS: %s', uq_sprintf_mat(MCResults.ModelEvaluations), uq_sprintf_mat(SSResults.ModelEvaluations));
        
        
    otherwise
        success = 1;
        fprintf('\nTest uq_test_subsetsim_mc finished successfully!\n');
end
if success == 0
    ErrStr = sprintf('\nError in uq_test_subsetsim_mc while comparing the %s\n', ErrMsg);
    error(ErrStr);
end



function Res = isinthreshold(A, B, TH)
Res = max(abs(A(:) - B(:))) < TH;