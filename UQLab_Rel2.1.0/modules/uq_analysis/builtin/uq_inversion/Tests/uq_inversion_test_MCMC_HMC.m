function [success] = uq_inversion_test_MCMC_HMC(level)
% UQ_INVERSION_TEST_MCMC_HMC tests the Hamiltonian Monte Carlo 
%   algorithm for a simple conjugate Gaussian problem.
%
%   See also: UQ_SELFTEST_UQ_INVERSION, UQ_HMC

%% START UQLAB
uqlab('-nosplash');
rng(5971)
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| ',mfilename,'...\n']);
%% PROBLEM SETUP
[y,Conj,PriorDist,ForwardModel,DiscrepancyOpt] = uq_inversion_test_conj_setup_M1;

%% SOLVER SETTINGS
Solver.Type = 'MCMC';
Solver.MCMC.Sampler = 'HMC';
Solver.MCMC.Steps = 2e2;
Solver.MCMC.LeapfrogSteps = 40;
Solver.MCMC.LeapfrogSize = 0.01 * sqrt(Conj.priorVariance);
Solver.MCMC.Mass = 1;
Solver.MCMC.NChains = 2;


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

if KLDiv < 0.02
    success = 1;
else
    success = 0;
end