function [success] = uq_inversion_test_func_CustomLikelihood(level)
% UQ_INVERSION_TEST_FUNC_CUSTOMLIKELIHOOD tests the functionality of the 
%   Bayesian module when called with a user-specified, custom likelihood
%   function.
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
%model parameters
for i = 1:Model.M
  Prior.Marginals(i).Name = sprintf('X%i',i);
  Prior.Marginals(i).Type = 'Gaussian';
  Prior.Marginals(i).Parameters = [0,1];
end
%error parameters
for i = Model.M+1:Model.M+2
  Prior.Marginals(i).Name = sprintf('X%i',i);
  Prior.Marginals(i).Type = 'Uniform';
  Prior.Marginals(i).Parameters = [0,20];
end
PriorDist = uq_createInput(Prior);


%% SOLVER SETTINGS
% use MCMC with very few steps
Solver.Type = 'MCMC';
Solver.MCMC.Sampler = 'AM';
Solver.MCMC.Steps = 1000;
Solver.MCMC.NChains = 2;
Solver.MCMC.Proposal.PriorScale = 1; 
Solver.MCMC.T0 = 500;

%% BAYESIAN MODEL
BayesOpt.Type = 'Inversion';
BayesOpt.Name = 'Bayesian model';
BayesOpt.Prior = PriorDist;
BayesOpt.Data.y = Data;
BayesOpt.Solver = Solver;
BayesOpt.LogLikelihood = @(params,data) ...
    uq_inversion_test_func_CustomLogLikelihood(params,data,Model.A);
BayesianAnalysis = uq_createAnalysis(BayesOpt);

%% SOME TESTING
try
  uq_inversion_test_InversionObject(BayesianAnalysis);
  success = 1;
catch
  success = 0;
end