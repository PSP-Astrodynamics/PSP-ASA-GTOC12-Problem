%% RBDO: SURROGATE-ASSISTED RBDO
%
% This example showcases the application of surrogate-assisted
% reliability-based design optimization (RBDO) to a two-dimensional
% mathematical problem featuring three constraints.

%%
% The RBDO problem is defined as:
%
% $$\mathbf{d}^\ast = \arg \min_{\mathbf{d}} d_1 + d_2 $$
%
% subject to: 
%
% $$P( g(\mathbf{X}(\mathbf{d})) \leq 0 ) \leq \bar{P}_f $$
%
% where:
%
% * $g(\mathbf{X}(\mathbf{d})) = \left\{g_1(\mathbf{X}(\mathbf{d})),
%   g_2(\mathbf{X}(\mathbf{d})), g_3(\mathbf{X}(\mathbf{d})) \right\}$
% * $\bar{P}_f = 0.0013$ (or equivalently $\bar{\beta} = 3$)
% * $\mathbf{d} = \{d_1,d_2\}$ are the design parameters

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL
%
% The limit state function is composed of three functions:
% 
% $$g_1(\mathbf{X}(\mathbf{d})) = X_1^2 X_2 / 20 - 1$$
%
% $$g_2(\mathbf{X}(\mathbf{d})) = (X_1 + X_2 - 5)^2 / 30 + (X_1 - X_2 - 12)^2/120 - 1$$
%
% $$g_3(\mathbf{X}(\mathbf{d})) = 80 / (X_1^2 + 8 X_2 + 5) - 1$$
%
% These functions are implemented in the function
% |uq_highlynonlinear_constraint| supplied with UQLab.

%%
% Create a MODEL object of this function using the file:
ModelOpts.mFile = 'uq_highlynonlinear_constraint';

myModel = uq_createModel(ModelOpts);

%% 3 - RELIABILITY-BASED DESIGN OPTIMIZATION (RBDO) SETUP

%% 3.1 Cost function
%
% The cost function reads:
%
% $$c(\mathbf{d}) = d_1 + d_2$$

%%
% Define this function using a string and assign it to the RBDO options:
RBDOOpts.Cost.mString = 'X(:,1) + X(:,2)';

%% 3.2 Constraint function
%
% The limit state function corresponds
% to the predefined computational model:
RBDOOpts.LimitState.Model = myModel;

%% 3.3 Design variables
%
% The design variables are modeled probabilistically and consist of two 
% random variables following a Gaussian distribution.
% The design parameters are the mean of the random variables.
%
% Define the design variables by specifying the distribution and
% standard deviation:
RBDOOpts.Input.DesVar(1).Name = 'd_1';
RBDOOpts.Input.DesVar(1).Type = 'Gaussian';
RBDOOpts.Input.DesVar(1).Std = 0.3;

RBDOOpts.Input.DesVar(2).Name = 'd_2';
RBDOOpts.Input.DesVar(2).Type = 'Gaussian';
RBDOOpts.Input.DesVar(2).Std = 0.3;

%% 
% Note that there are no environmental variables for this example.

%% 3.4 Optimization setup

%%
% To specify the optimization problem,
% first define the bounds of the search (or design) space:
RBDOOpts.Optim.Bounds = [0 0; 10 10];

%%
% Optionally, the starting point for the optimization algorithm can also be
% provided:
RBDOOpts.Optim.StartingPoint = [4 5];

%%
% Set the target reliability index:
RBDOOpts.TargetBeta = 3;

%%
% Set the maximum number of iterations:
RBDOOpts.Optim.MaxIter = 500;

%% 4 - SURROGATE-ASSISTED RELIABILITY-BASED DESIGN OPTIMIZATION (RBDO)
%
% RBDO is performed using the Quantile Monte Carlo (QMC) method.
% Surrogate models are introduced in the framework considering
% three different schemes:
%
% * SVR with a fixed Experimental design of size 50
% * PCE with adaptive experimental design
% * Kriging with adaptive experimental design

%%
% Select QMC as the RBDO method:
RBDOOpts.Type = 'RBDO';
RBDOOpts.Method = 'QMC';

%% 4.1 Support vector machines for regression (SVR)
%
% Initialize the options for SVR-assisted RBDO:
RBDO_SVROpts = RBDOOpts;

%%
% Specify the metamodel type for RBDO:
RBDO_SVROpts.Metamodel.Type = 'SVR';

%%
% Set the options for the SVR metamodel:
SVROpts.Loss = 'l2-eps';
SVROpts.Kernel.Family = 'matern-5_2';
SVROpts.Kernel.Isotropic = false;
SVROpts.Optim.Method = 'HCMAES';
SVROpts.ExpDesign.NSamples = 50;

%%
% Specify the options for the construction of the SVR metamodel:
RBDO_SVROpts.Metamodel.SVR = SVROpts;

%%
% Specify IP as the optimization algorithm:
RBDO_SVROpts.Optim.Method = 'IP';

%%
% Run the RBDO analysis:
myRBDO_SVR = uq_createAnalysis(RBDO_SVROpts);

%%
% Print out a report of the results:
uq_print(myRBDO_SVR)

%%
% Display a graphical representation of the results:
uq_display(myRBDO_SVR)

%% 4.2 Polynomial chaos expansions (PCE)
%
% Initialize the options for PCE-assisted RBDO:
RBDO_PCEOpts = RBDOOpts;

%%
% Specify PCE as the metamodel type for RBDO:
RBDO_PCEOpts.Metamodel.Type = 'PCE';

%%
% Set the options for the PCE metamodel:
PCEOpts.Degree = 2:10 ;
PCEOpts.ExpDesign.NSamples = 10 ;
PCEOpts.ExpDesign.Sampling = 'LHS' ;

%%
% Specify the options for the construction of the PCE metamodel to the RBDO
% options:
RBDO_PCEOpts.Metamodel.PCE = PCEOpts;

%%
% Specify the enrichment options for the adaptive experimental design:
RBDO_PCEOpts.Metamodel.Enrichment.Convergence = {'stopSign','stopDf'};
RBDO_PCEOpts.Metamodel.Enrichment.ConvThreshold = 0.001;
RBDO_PCEOpts.Metamodel.Enrichment.MaxAdded = 50;
RBDO_PCEOpts.Metamodel.Enrichment.MOStrategy = 'mean';  

%% 
% Run the RBDO analysis:
myRBDO_PCE = uq_createAnalysis(RBDO_PCEOpts);

%%
% Print out a report of the results:
uq_print(myRBDO_PCE)

%%
% Display a graphical representation of the results:
uq_display(myRBDO_PCE)

%% 4.3  Kriging
%
% Initialize the options for Kriging-assisted RBDO:
RBDO_KrgOpts = RBDOOpts;

%%
% Select Kriging as the metamodel type for RBDO:
RBDO_KrgOpts.Metamodel.Type = 'Kriging';

%%
% Set the options for the Kriging metamodel:
KrgOpts.EstimMethod = 'ML';
KrgOpts.Corr.Family = 'matern-5_2';
KrgOpts.Corr.Isotropic = false;
KrgOpts.Optim.Method = 'HGA';
KrgOpts.ExpDesign.NSamples = 10;

%%
% Specify the options for the construction of the Kriging metamodel"
RBDO_KrgOpts.Metamodel.KRIGING = KrgOpts;

%%
% Specify the enrichment options for the adaptive experimental design:
RBDO_KrgOpts.Metamodel.Enrichment.Convergence = {'stopSign','stopDf'};
RBDO_KrgOpts.Metamodel.Enrichment.ConvThreshold = 0.001;
RBDO_KrgOpts.Metamodel.Enrichment.MaxAdded = 50;
RBDO_KrgOpts.Metamodel.Enrichment.Points = 2;

%%
% Specify SQP as the optimization algorithm:
RBDO_KrgOpts.Optim.Method = 'SQP';

%% 
% Run the RBDO analysis:
myRBDO_Krg = uq_createAnalysis(RBDO_KrgOpts);

%%
% Print out a report of the results:
uq_print(myRBDO_Krg)

%%
% Display a graphical representation of the results:
uq_display(myRBDO_Krg)
