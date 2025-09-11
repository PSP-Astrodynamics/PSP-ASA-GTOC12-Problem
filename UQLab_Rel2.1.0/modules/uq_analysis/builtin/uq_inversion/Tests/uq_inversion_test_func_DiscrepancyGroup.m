function [success] = uq_inversion_test_func_DiscrepancyGroup(level)
% UQ_INVERSION_TEST_FUNC_DISCREPANCYGROUP tests the functionality of the 
%   Bayesian inversion module for multiple discrepancy/data groups.
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
PriorDist = uq_createInput(Prior);

%% FORWARD MODEL
ModelOpt.Name = 'Forward model';
ModelOpt.mHandle = @(x) x * Model.A;
ModelOpt.isVectorized = true;
ForwardModel.Model = uq_createModel(ModelOpt);

%% DATA 
myData(1).y = Data(1,1:12);
myData(1).MOMap = (1:12);
myData(1).Name = 'First Data';
myData(2).y = Data(1,13:24);
myData(2).MOMap = [ones(1,12);(13:24)];
myData(2).Name = 'Second Data';

%% DISCREPANCY MODEL
DiscrepancyOpt(1).Type = 'Gaussian';
DiscrepancyOpt(1).Parameters = 1;

SigmaOpt.Name = 'Prior of sigma';
SigmaOpt.Marginals(1).Name = 'Sigma';
SigmaOpt.Marginals(1).Type = 'Uniform';
SigmaOpt.Marginals(1).Parameters = [0,20];
SigmaDist = uq_createInput(SigmaOpt);
DiscrepancyOpt(2).Type = 'Gaussian';
DiscrepancyOpt(2).Prior = SigmaDist;

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
BayesOpt.ForwardModel = ForwardModel;
BayesOpt.Data = myData;
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