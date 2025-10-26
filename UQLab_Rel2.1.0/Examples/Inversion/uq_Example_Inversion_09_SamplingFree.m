%% INVERSION: SAMPLING FREE INVERSION
% 
% In this example, we use sampling-free approaches to solve again the
% problem from |uq_Example_Inversion_01_Beam|. The two approaches we
% compare are _spectral likelihood expansions_ (SLE) and _Stochastic
% spectral likelihood embedding_ (SSLE).

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - SETTING UP INVERSE PROBLEM
%
% The model setup is identical to |uq_Example_Inversion_01_Beam|. For
% further details, refer to the original example.

%% 2.1 - Forward model
% Define the forward model as a UQLab MODEL object:
ModelOpts.mFile = 'uq_SimplySupportedBeam';
ModelOpts.isVectorized = true;

myForwardModel = uq_createModel(ModelOpts);

%% 2.2 - Prior distribution
%
% Specify the pior distribution as a UQLab INPUT object:
PriorOpts.Marginals(1).Name = 'b';               % beam width 
PriorOpts.Marginals(1).Type = 'Constant';
PriorOpts.Marginals(1).Parameters = [0.15];      % (m)

PriorOpts.Marginals(2).Name = 'h';               % beam height 
PriorOpts.Marginals(2).Type = 'Constant';
PriorOpts.Marginals(2).Parameters = [0.3];       % (m)

PriorOpts.Marginals(3).Name = 'L';               % beam length 
PriorOpts.Marginals(3).Type = 'Constant';
PriorOpts.Marginals(3).Parameters = 5;           % (m)

PriorOpts.Marginals(4).Name = 'E';               % Young's modulus
PriorOpts.Marginals(4).Type = 'LogNormal';
PriorOpts.Marginals(4).Moments = [30 4.5]*1e9;   % (N/m^2)

PriorOpts.Marginals(5).Name = 'p';               % uniform load 
PriorOpts.Marginals(5).Type = 'Gaussian';
PriorOpts.Marginals(5).Moments = [12000 600]; % (N/m)

myPriorDist = uq_createInput(PriorOpts);

%% 2.3 - Measurement data
%
% The data is stored in the column vector |y|:
myData.y = [12.84; 13.12; 12.13; 12.19; 12.67]/1000; % (m)
myData.Name = 'Mid-span deflection';

%% 2.4 - Discrepancy model
%
% We use the default discrepancy model set up by UQLAB.

%% 2.5 - Assign Bayesian options
%
% To initialize the Bayesian analysis, explicitly assign the following 
% options to the |BayesOpts| structure:
BayesOpts.Type = 'Inversion';
BayesOpts.Data = myData;

%% 3 - SPECTRAL LIKELIHOOD EXPANSION (SLE)
%
% The first sampling free approach we test here is SLE proposed by Nagel
% and Sudret (2016). In this approach, the likelihood function is
% approximated with a PCE constructed with the PCE module of UQLAB. 

%%
% Specify SLE as the solver:
SLESolver.Type = 'SLE';
BayesOpts.Solver = SLESolver;

%%
% The |BayesOpts.Solver.SLE| field then accepts further PCE-specific options. To
% set the experimental design size to 1000, the following should be
% specified:
BayesOpts.Solver.SLE.ExpDesign.NSamples = 1000;

%%
% Run the Bayesian inversion analysis:
myBayesianAnalysis_SLE = uq_createAnalysis(BayesOpts);

%%
% Print out a report of the results:
uq_print(myBayesianAnalysis_SLE)

%%
% Create a graphical representation of the results:
uq_display(myBayesianAnalysis_SLE)

%% 4 - STOCHASTIC SPECTRAL LIKELIHOOD EMBEDDING (SSLE)
%
% The second sampling free approach we test here is SSLE proposed by Wagner
% (2021). In this approach, the likelihood function is approximated with a
% SSE constructed with the SSE module of UQLAB.

%%
% Specify SLE as the solver:
SLESolver.Type = 'SSLE';
BayesOpts.Solver = SLESolver;

%%
% The |BayesOpts.Solver.SSLE| field then accepts further SSE-specific 
% options. To set the experimental design size to 1000, with sequential 
% sample enrichment of 50 samples per refinement step, the following should 
% be specified:
BayesOpts.Solver.SSLE.ExpDesign.NSamples = 1000;
BayesOpts.Solver.SSLE.ExpDesign.NEnrich = 50;

%%
% Specify the adaptive polynomial degree of the residual expansions:
BayesOpts.Solver.SSLE.ExpOptions.Degree = 0:2;

%%
% Run the Bayesian inversion analysis:
myBayesianAnalysis_SSLE = uq_createAnalysis(BayesOpts);

%%
% Print out a report of the results:
uq_print(myBayesianAnalysis_SSLE)

%%
% Create a graphical representation of the results:
uq_display(myBayesianAnalysis_SSLE)

%%
% *References*
%
% * Wagner, P.-R., Marelli, S., Sudret, B., Bayesian model inversion using 
%   stochastic spectral embedding, Journal of Computational Physics, 
%   436:110141(2021). DOI: <https://doi.org/10.1016/j.jcp.2021.110141 10.1016/j.jcp.2021.110141>
% * Marelli, S., Wagner, P.-R., Lataniotis, C., Sudret, B., Stochastic 
%   spectral embedding, International Journal for Uncertainty 
%   Quantification, 11(2):25–47(2021). 
%   DOI: <https://doi.org/10.1615/Int.J.UncertaintyQuantification.2020034395 10.1615/Int.J.UncertaintyQuantification.2020034395>
% * Nagel, J., Sudret, B., Spectral likelihood expansions for Bayesian 
%   inference, Journal of Computational Physics, 309:267-294(2016). 
%   DOI: <https://doi.org/10.1016/j.jcp.2015.12.047 10.1016/j.jcp.2015.12.047>