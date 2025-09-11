function [success] = uq_inversion_test_postProc(level)
% UQ_INVERSION_TEST_POSTPROC tests the UQ_POSTPROCESSINVERSIONMCMC function for 
%   a simple inverse analysis.
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

%% PRIOR DISTRIBUTION
Prior.Name = 'Prior distribution';
for i = 1:Model.M
  Prior.Marginals(i).Name = sprintf('X%i',i);
  Prior.Marginals(i).Type = 'Gaussian';
  Prior.Marginals(i).Parameters = [0,1];
end
% Make first and last parameter constant
Prior.Marginals(1).Type = 'Constant';
Prior.Marginals(1).Parameters = 0.8993;
Prior.Marginals(end).Type = 'Constant';
Prior.Marginals(end).Parameters = -0.3483;
PriorDist = uq_createInput(Prior);

%% FORWARD MODEL
ModelOpt.Name = 'Forward model';
ModelOpt.mHandle = @(x) x * Model.A;
ModelOpt.isVectorized = true;
ForwardModel.Model = uq_createModel(ModelOpt);

%% SOLVER
Solver.Type = 'MCMC';
Solver.MCMC.Sampler = 'AM';
Solver.MCMC.Steps = 1e3;
Solver.MCMC.NChains = 1e1;
Solver.MCMC.T0 = 1e2;
Solver.MCMC.Proposal.PriorScale = 0.1;

%% DISCREPANCY
DiscrepancyOpts.Type = 'Gaussian';
DiscrepancyOpts.Parameters = 1;

%% BAYESIAN MODEL
BayesOpt.Type = 'Inversion';
BayesOpt.Name = 'Bayesian model';
BayesOpt.Prior = PriorDist;
BayesOpt.ForwardModel = ForwardModel;
BayesOpt.Solver = Solver;
BayesOpt.Data.y = Data;
BayesOpt.Discrepancy = DiscrepancyOpts;
BayesianAnalysis = uq_createAnalysis(BayesOpt);

%% TEST postProc
try
  uq_postProcessInversion(BayesianAnalysis,...
      'burnIn', 5,...
      'badChains', 2,...
      'pointEstimate',{'mean','map',[1:Model.M-2;1:Model.M-2]},...
      'gelmanRubin', true,...
      'priorPredictive', 20,...
      'posteriorPredictive', 20);
  uq_postProcessInversion(BayesianAnalysis,...
      'burnIn', Solver.MCMC.Steps-1);
  success = 1;
catch
  success = 0;
end