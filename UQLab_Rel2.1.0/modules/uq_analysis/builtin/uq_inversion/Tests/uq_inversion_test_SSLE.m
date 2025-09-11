function [success] = uq_inversion_test_SSLE(level)
% UQ_INVERSION_TEST_SSE tests the functionality of SSE-based inversion.
%
%   See also: UQ_SELFTEST_UQ_INVERSION

%% START UQLAB
uqlab('-nosplash');
rng(8801)
if nargin < 1
    level = 'normal';
end
fprintf(['\nRunning: |' level '| ',mfilename,'...\n']);
%% PROBLEM SETUP
[y,Conj,PriorDist,ForwardModel,DiscrepancyOpt] = uq_inversion_test_conj_setup_M2;

% add constant to prior
uq_removeInput(1); uq_removeModel(1);
InputOpt = PriorDist.Options;
InputOpt.Marginals(3).Name = 'X3';
InputOpt.Marginals(3).Type = 'Constant';
InputOpt.Marginals(3).Parameters = rand(1);
PriorDist = uq_createInput(InputOpt);
% modify forward model
ForwardModelOpt = ForwardModel.Model.Options;
ForwardModelOpt.mHandle = @(x) x(:,1:2);
ForwardModel.Model = uq_createModel(ForwardModelOpt);

%% SOLVER SETTINGS
Solver.Type = 'SSLE';
Solver.SSLE.ExpOptions.TruncOptions.MaxInteraction = 2;
Solver.SSLE.ExpOptions.TruncOptions.qNorm = 0.5:0.1:0.8;
Solver.SSLE.ExpOptions.Degree = 0:4;
% maximum polynomial degree
Solver.SSLE.Refine.NExp = 100;

% Experimental design
Solver.SSLE.ExpDesign.Sampling = 'Sequential';
Solver.SSLE.ExpDesign.NSamples = 1e3;
Solver.SSLE.ExpDesign.NEnrich = 100;

%% BAYESIAN MODEL
BayesOpt.Type = 'Inversion';
BayesOpt.Name = 'Bayesian model SSE';
BayesOpt.Prior = PriorDist;
BayesOpt.ForwardModel = ForwardModel;
BayesOpt.Data.y = y;
BayesOpt.Discrepancy = DiscrepancyOpt;
BayesOpt.Solver = Solver;
myBayesianAnalysis = uq_createAnalysis(BayesOpt);


%% SOME TESTING
%Compute KL divergence between conjugate and samples
maxAvailableRefine = max(myBayesianAnalysis.Results.SSLE.SSE.Graph.Nodes.ref);
uq_postProcessInversion(myBayesianAnalysis,'dependence',true,'maxrefine',1:maxAvailableRefine)

KLDiv = uq_inversion_test_conj_computeKL(myBayesianAnalysis,Conj);

if KLDiv < 0.05
    success = 1;
else
    success = 0;
end

H = uq_display(myBayesianAnalysis, 'densityplot', [2 1]);
close(H{:})

% do some print tests
uq_print(myBayesianAnalysis)
end