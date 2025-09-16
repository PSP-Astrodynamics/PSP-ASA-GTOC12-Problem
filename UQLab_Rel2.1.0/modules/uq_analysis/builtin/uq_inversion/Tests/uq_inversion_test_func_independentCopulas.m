function [success] = uq_inversion_test_func_independentCopulas(level)
% UQ_INVERSION_TEST_FUNC_INDEPENDENTCOPULAS tests the functionality of the 
%   inversion module with block independence in the copulas
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
% 8D prior with standard normal marginals and complex dependence defined by
% # $(X_1,X_4,X_6)$: Vine copula
% # $(X_3,X_7)$: Gaussian copula
% # $(X_2,X_8)$: t- pair copula
% # $X_5$: stand-alone

Prior.Name = 'Prior distribution';
Prior.Marginals = uq_StdNormalMarginals(Model.M);

Prior.Copula(1) = uq_VineCopula('CVine', 1:3, ...
    {'Clayton', 'Gumbel', 'Gaussian'}, {1.4, 2, 0.3}, [0 0 0]);
Prior.Copula(1).Variables = [1 4 6];

Prior.Copula(2) = uq_GaussianCopula([1 -.5; -.5 1]);
Prior.Copula(2).Variables = [3 7];

Prior.Copula(3) = uq_PairCopula('t', [.5 2], 0);
Prior.Copula(3).Variables = [2 8];
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