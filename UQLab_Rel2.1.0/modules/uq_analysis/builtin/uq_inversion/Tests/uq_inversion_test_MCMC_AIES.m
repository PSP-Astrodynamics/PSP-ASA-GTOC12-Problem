function [success] = uq_inversion_test_MCMC_AIES(level)
% UQ_INVERSION_TEST_MCMC_AIES tests the affine invariant ensemble algorithm
%   for a simple conjugate Gaussian problem.
%
%   See also: UQ_SELFTEST_UQ_INVERSION, UQ_AIES

%% START UQLAB
uqlab('-nosplash');
rng(1567);
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| ',mfilename,'...\n']);
%% PROBLEM SETUP
[y,Conj,PriorDist,ForwardModel,DiscrepancyOpt] = uq_inversion_test_conj_setup_M1;

%% SOLVER SETTINGS
Solver.Type = 'MCMC';
Solver.MCMC.Sampler = 'AIES';
Solver.MCMC.Steps = 60;
Solver.MCMC.NChains = 100;
Solver.MCMC.a = 2; 

%% BAYESIAN MODEL
BayesOpt.Type = 'Inversion';
BayesOpt.Name = 'Bayesian model';
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