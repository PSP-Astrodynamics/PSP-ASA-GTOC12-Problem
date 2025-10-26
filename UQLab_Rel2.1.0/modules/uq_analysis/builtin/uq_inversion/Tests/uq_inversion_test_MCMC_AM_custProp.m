function [success] = uq_inversion_test_MCMC_AM_custProp(level)
% UQ_INVERSION_TEST_MCMC_AM_RWM tests the adaptive Metropolis algorithm 
%   for a simple conjugate Gaussian problem with an initial custom proposal
%   distribution.
%
%   See also: UQ_SELFTEST_UQ_INVERSION, UQ_AM

%% START UQLAB
uqlab('-nosplash');
rng(1724)
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| ',mfilename,'...\n']);
%% PROBLEM SETUP
[y,Conj,PriorDist,ForwardModel,DiscrepancyOpt] = uq_inversion_test_conj_setup_M1;

%% SOLVER SETTINGS
%Specify proposal options
propOpt.Name = 'Proposal distribution';
propOpt.Marginals(1).Name = 'X1';
propOpt.Marginals(1).Type = 'Gaussian';
propOpt.Marginals(1).Moments = [Conj.posteriorMean,sqrt(Conj.posteriorVariance)];
myProposal = uq_createInput(propOpt);

%assign to Proposal struct
Proposal.Distribution = myProposal;
Proposal.Conditioning = 'Global'; %Previous 

Solver.Type = 'MCMC';
Solver.MCMC.Sampler = 'AM';
Solver.MCMC.Steps = 1e3;
Solver.MCMC.NChains = 2;
Solver.MCMC.Proposal = Proposal;
Solver.MCMC.T0 = 1e2; 

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