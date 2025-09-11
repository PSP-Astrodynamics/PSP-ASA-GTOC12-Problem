function [success] = uq_inversion_test_func_MultiModels_multiDiscrepancy(level)
% UQ_INVERSION_TEST_FUNC_MULTIMODELS tests the functionality of 
%   Bayesian inversion module for multiple forward models with multiple
%   discrepancy groups
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
for i = 1:Model.M*2
  Prior.Marginals(i).Name = sprintf('X%i',i);
  Prior.Marginals(i).Type = 'Gaussian';
  Prior.Marginals(i).Parameters = [0,1];
end
PriorDist = uq_createInput(Prior);

%% FORWARD MODEL
ModelOpt.Name = 'Forward model';
ModelOpt.mHandle = @(x) x * Model.A;
ModelOpt.isVectorized = true;
myModel = uq_createModel(ModelOpt);

% model structure
ForwardModel(1).Model = 'Forward model';
ForwardModel(1).PMap = 1:8;
ForwardModel(2).Model = myModel;
ForwardModel(2).PMap = 9:16;

%% DATA
myData(1).y = [Data,Data(1:12);Data,Data(1:12)];
myData(1).MOMap = [ones(1,24),2*ones(1,12);...
                (1:24),(1:12)];
            
myData(2).y = [Data(1:24);Data(1:24)];
myData(2).MOMap = [2*ones(1,24);...
                (1:24)];
            
myData(3).y = [Data(1);Data(1);Data(1)];
myData(3).MOMap = [2;...
                1];
myData(3).Name = 'Test name of data';

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

DiscrepancyOpt(3).Type = 'Gaussian';
DiscrepancyOpt(3).Parameters = 1;

%% SOLVER SETTINGS
% use MCMC with very few steps
Solver.Type = 'MCMC';
Solver.MCMC.Sampler = 'AM';
Solver.MCMC.Steps = 50;
Solver.MCMC.NChains = 2;
Solver.MCMC.Proposal.PriorScale = 1; 
Solver.MCMC.T0 = 1e3;

%% BAYESIAN MODEL
BayesOpt.Type = 'Inversion';
BayesOpt.Name = 'Bayesian model';
BayesOpt.Prior = PriorDist;
BayesOpt.ForwardModel = ForwardModel;
BayesOpt.Data = myData;
BayesOpt.Discrepancy = DiscrepancyOpt;
BayesOpt.Solver = Solver;
BayesianAnalysis = uq_createAnalysis(BayesOpt);

% post Process to create prior predictive samples
uq_postProcessInversion(BayesianAnalysis,'priorPredictive',1000)

%% SOME TESTING
try
  uq_inversion_test_InversionObject(BayesianAnalysis);
  H = uq_display(BayesianAnalysis,'predDist','true');
  close(H{:})
  success = 1;
catch
  success = 0;
end