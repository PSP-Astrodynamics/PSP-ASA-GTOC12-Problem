function [success] = uq_inversion_test_func_SigmaKnownScalar_WithConstant(level)
% UQ_INVERSION_TEST_FUNC_SIGMAKNOWNSCALAR_WITHCONSTANTS tests the 
%   functionality of the Bayesian inversion module for known scalar 
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
Prior.Marginals(Model.M).Name = sprintf('X%i',Model.M);
Prior.Marginals(Model.M).Type = 'Constant';
Prior.Marginals(Model.M).Parameters = 0;
PriorDist = uq_createInput(Prior);

%% FORWARD MODEL
ModelOpt.Name = 'Forward model';
ModelOpt.mHandle = @(x) x * Model.A;
ModelOpt.isVectorized = true;
ForwardModel.Model = uq_createModel(ModelOpt);

%% DISCREPANCY MODEL
DiscrepancyOpt.Type = 'Gaussian';
DiscrepancyOpt.Parameters = 1;

%% SOLVER SETTINGS
% use MCMC with very few steps
Solver.Type = 'MCMC';
Solver.MCMC.Sampler = 'AM';
Solver.MCMC.Steps = 100;
Solver.MCMC.NChains = 2;
Solver.MCMC.Proposal.PriorScale = 1; 
Solver.MCMC.T0 = 1e3;

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