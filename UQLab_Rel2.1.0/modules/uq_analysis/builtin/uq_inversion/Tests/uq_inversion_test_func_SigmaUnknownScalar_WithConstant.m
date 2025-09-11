function [success] = uq_inversion_test_func_SigmaUnknownScalar_WithConstant(level)
% UQ_INVERSION_TEST_FUNC_SIGMAUNKNOWNSCALAR_WITHCONSTANTS tests the 
%   functionality of Bayesian inversion module for unknown scalar 
%   discrepancy variance with constants in the prior distribution.
%
%   See also: UQ_SELFTEST_UQ_INVERSION
%% START UQLAB
uqlab('-nosplash');

if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| ',mfilename,'...\n']);
%% PROBLEM SETUP
load('uq_Example_BayesianLinearRegression');

%% CONSTANT PARAMETER
Prior.Name = 'Prior distribution';
for i = 1:Model.M-1
  Prior.Marginals(i).Name = sprintf('X%i',i);
  Prior.Marginals(i).Type = 'Gaussian';
  Prior.Marginals(i).Parameters = [0,1];
end
% make first and last parameter a constant
Prior.Marginals(1).Type = 'Constant';
Prior.Marginals(1).Parameters = 0;
Prior.Marginals(Model.M).Type = 'Constant';
Prior.Marginals(Model.M).Parameters = 0;
PriorDist = uq_createInput(Prior);

%% FORWARD MODEL
ModelOpt.Name = 'Forward model';
ModelOpt.mHandle = @(x) x * Model.A;
ModelOpt.isVectorized = true;
ForwardModel.Model = uq_createModel(ModelOpt);

%% UNKNOWN SIGMA
DiscrepancyPriorOpt.Name = 'Prior of sigma';
DiscrepancyPriorOpt.Marginals(1).Name = 'Sigma';
DiscrepancyPriorOpt.Marginals(1).Type = 'Uniform';
DiscrepancyPriorOpt.Marginals(1).Parameters = [0,20];
DiscrepancyPrior = uq_createInput(DiscrepancyPriorOpt);
DiscrepancyOpt.Type = 'Gaussian';
DiscrepancyOpt.Prior = DiscrepancyPrior;

%% SOLVER SETTINGS
% use MCMC with very few steps
Solver.Type = 'MCMC';
Solver.MCMC.Sampler = 'AM';
Solver.MCMC.Steps = 1e3;
Solver.MCMC.NChains = 2; 
Solver.MCMC.Proposal.PriorScale = 1; 
Solver.MCMC.T0 = 5e2;

%% BAYESIAN MODEL
BayesOpt.Type = 'Inversion';
BayesOpt.Name = 'Bayesian model';
BayesOpt.Prior = PriorDist;
BayesOpt.ForwardModel = ForwardModel;
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