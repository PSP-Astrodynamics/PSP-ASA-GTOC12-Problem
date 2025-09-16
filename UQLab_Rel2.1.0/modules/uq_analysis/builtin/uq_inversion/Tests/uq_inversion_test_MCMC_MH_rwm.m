function [success] = uq_inversion_test_MCMC_MH_rwm(level)
% UQ_INVERSION_TEST_MCMC_MH_RWM tests the Metropolis-Hastings 
%   algorithm for a simple conjugate Gaussian problem with a Gaussian
%   proposal distribution.
%
%   See also: UQ_SELFTEST_UQ_INVERSION, UQ_MH

%% START UQLAB
uqlab('-nosplash');
rng(8801)
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| ',mfilename,'...\n']);
%% PROBLEM SETUP
[y,Conj,PriorDist,ForwardModel,DiscrepancyOpt] = uq_inversion_test_conj_setup_M2;

%% SOLVER SETTINGS - Simple RWM
Solver.Type = 'MCMC';
Solver.MCMC.Sampler = 'MH';
Solver.MCMC.Steps = 1e3;
Solver.MCMC.NChains = 2;
Solver.MCMC.Proposal.Cov = Conj.priorVariance;

%% BAYESIAN MODEL
BayesOpt.Type = 'Inversion';
BayesOpt.Name = 'Bayesian model RWM';
BayesOpt.Prior = PriorDist;
BayesOpt.ForwardModel = ForwardModel;
BayesOpt.Data.y = y;
BayesOpt.Discrepancy = DiscrepancyOpt;
BayesOpt.Solver = Solver;
BayesianAnalysis = uq_createAnalysis(BayesOpt);


%% SOME TESTING
%Compute KL divergence between conjugate and samples
KLDiv = uq_inversion_test_conj_computeKL(BayesianAnalysis,Conj);

if KLDiv < 0.01
    success = 1;
else
    success = 0;
end