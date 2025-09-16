function [success] = uq_inversion_test_func_AIES(level)
% UQ_INVERSION_TEST_FUNC_AIES tests the functionality of the affine
%   invariant ensemble sampler algorithm
%
%   See also: UQ_SELFTEST_UQ_INVERSION

%% START UQLAB
uqlab('-nosplash');

if nargin < 1
    level = 'normal'; % TBD: Time that the tests will take
end
fprintf(['\nRunning: |' level '| ',mfilename,'...\n']);

%% PROBLEM SETUP
load('uq_Example_BayesianLinearRegression');

%% PRIOR DISTRIBUTION
Prior.Name = 'Prior distribution';
for i = 1:Model.M
  Prior.Marginals(i).Name = sprintf('X%i',i);
  Prior.Marginals(i).Type = 'Gaussian';
  Prior.Marginals(i).Parameters = [0,1];
end
PriorDist = uq_createInput(Prior);

%% FORWARD MODEL
ModelOpt.Name = 'Forward model';
ModelOpt.mHandle = @(x) x * Model.A;
ModelOpt.isVectorized = true;
myForwardModel = uq_createModel(ModelOpt);

%% UNKNOWN SIGMA
DiscrepancyPriorOpt.Name = 'Prior of sigma';
for ii = 1:size(Data,2)
    DiscrepancyPriorOpt.Marginals(ii).Name = 'Sigma';
    DiscrepancyPriorOpt.Marginals(ii).Type = 'Uniform';
    DiscrepancyPriorOpt.Marginals(ii).Parameters = [0,20];
end
DiscrepancyPrior = uq_createInput(DiscrepancyPriorOpt);
DiscrepancyOpt.Type = 'Gaussian';
DiscrepancyOpt.Prior = DiscrepancyPrior;

%% SOLVER SETTINGS
% use MCMC with very few steps
Solver.Type = 'MCMC';
Solver.MCMC.Sampler = 'AIES';
Solver.MCMC.Steps = 100;
Solver.MCMC.NChains = 2;

%% BAYESIAN MODEL
BayesOpt.Type = 'Inversion';
BayesOpt.Name = 'Bayesian model';
BayesOpt.Prior = PriorDist;
BayesOpt.ForwardModel = myForwardModel;
BayesOpt.Data.y = [Data;Data];
BayesOpt.Discrepancy = DiscrepancyOpt;
BayesOpt.Solver = Solver;
BayesianAnalysis = uq_createAnalysis(BayesOpt);

%% SOME TESTING
try
  uq_inversion_test_InversionObject(BayesianAnalysis);
  success = 1;
catch
  success = 0;
end