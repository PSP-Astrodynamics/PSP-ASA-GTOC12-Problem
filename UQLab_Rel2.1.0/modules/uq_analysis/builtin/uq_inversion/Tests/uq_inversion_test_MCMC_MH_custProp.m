function [success] = uq_inversion_test_MCMC_MH_custProp(level)
% UQ_INVERSION_TEST_MCMC_MH_CUSTPROP tests the Metropolis-Hastings 
%   algorithm for a simple conjugate Gaussian problem with a custom
%   proposal distribution.
%
%   See also: UQ_SELFTEST_UQ_INVERSION, UQ_MH

%% START UQLAB
uqlab('-nosplash');
rng(8901)
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| ',mfilename,'...\n']);
%% PROBLEM SETUP
[y,Conj,PriorDist,ForwardModel,DiscrepancyOpt] = uq_inversion_test_conj_setup_M1;

%% SOLVER SETTINGS - General non symmetric MH
%Specify proposal options
propOpt.Name = 'Proposal distribution';
propOpt.Marginals(1).Name = 'X1';
propOpt.Marginals(1).Type = 'Gaussian';
propOpt.Marginals(1).Moments = [1,sqrt(Conj.priorVariance)];
propDist = uq_createInput(propOpt);

%assign to Proposal struct
Proposal.Distribution = propDist;
Proposal.Conditioning = 'Previous'; %Global 

Solver.Type = 'MCMC';
Solver.MCMC.Sampler = 'MH';
Solver.MCMC.Steps = 2e2;
Solver.MCMC.NChains = 2;
Solver.MCMC.Proposal = Proposal;

%% BAYESIAN MODEL
BayesOpt.Type = 'Inversion';
BayesOpt.Name = 'Bayesian model MH';
BayesOpt.Prior = PriorDist;
BayesOpt.ForwardModel = ForwardModel;
BayesOpt.Data.y = y;
BayesOpt.Discrepancy = DiscrepancyOpt;
BayesOpt.Solver = Solver;
BayesianAnalysis = uq_createAnalysis(BayesOpt);

%% SOME TESTING
%Compute KL divergence between conjugate and samples
KLDiv = uq_inversion_test_conj_computeKL(BayesianAnalysis,Conj);

if KLDiv < 0.05
    success = 1;
else
    success = 0;
end