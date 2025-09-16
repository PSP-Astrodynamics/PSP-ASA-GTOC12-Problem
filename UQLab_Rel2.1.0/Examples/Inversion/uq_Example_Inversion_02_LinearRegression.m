%% INVERSION: BAYESIAN LINEAR REGRESSION
%
% This example solves the Bayesian linear regression problem,
% a standard example in the Bayesian data analysis literature.
% The problem is first solved assuming a known variance
% of the discrepancy term.
% In a second step, the problem is solved again assuming instead an unknown
% variance in the discrepancy model. 

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - FORWARD MODEL
%
% The linear model is defined by a regression matrix $\mathbf{A}$
% that maps an $8$-dimensional input parameter vector $\mathbf{x}$ $(M=8)$ 
% to a $24$-dimensional output vector $\tilde{\mathbf{y}}$ $(N_{out}=24)$:
%
% $$\tilde{\mathbf{y}} = \mathbf{A} \mathbf{x}$$
%
% Load the constant matrix $A$ of size $24 \times 8$ which defines
% the linear model (contained in a structure |Model|) and the data |Data|:

load('uq_Example_BayesianLinearRegression')

% Define the forward model as a UQLab MODEL object:

ModelOpts.mHandle = @(x) x * Model.A;
ModelOpts.isVectorized = true;

myForwardModel = uq_createModel(ModelOpts);

%% 3 - PRIOR DISTRIBUTION OF THE MODEL PARAMETERS
%
% A simple standard normal prior model is assumed on the input variables
%
% $$X_i \sim \mathcal{N}(0, 1)\quad i = 1,...,8$$
%
% Specify these distributions as a UQLab INPUT object:

for i = 1:Model.M
  PriorOpts.Marginals(i).Type = 'Gaussian';
  PriorOpts.Marginals(i).Parameters = [0 1];
end

myPriorDist = uq_createInput(PriorOpts);

%% 4 - MEASUREMENT DATA
%
% Provide the set of measurements that are stored in the |Data| vector to
% the measurement vector |y|
myData.y = Data;

%% 5 - SOLVER OPTIONS
%
% In this example, the Bayesian calibration is solved with 
% an adaptive Metropolis algorithm using $10^2$ chains of length $10^3$
% iterations each
Solver.Type = 'MCMC';
Solver.MCMC.Sampler = 'AM';
Solver.MCMC.Steps = 1e3;
Solver.MCMC.NChains = 1e2;
Solver.MCMC.T0 = 1e2;
Solver.MCMC.Proposal.PriorScale = 0.1;

%% 6 - BAYESIAN ANALYSIS WITH KNOWN MEASUREMENT ERROR

%% 6.1 Discrepancy model
%
% The forward model and measurement data are related through an additive 
% residual $\mathbf{\varepsilon} = \{\varepsilon_i;\; i = 1,...,24\}$:
%
% $$\mathbf{y} = \tilde{\mathbf{y}} + \mathbf{\varepsilon}$$
%
% where $\varepsilon_i$'s are independent 
% and identically distributed Gaussian random variables:
%
% $$\varepsilon_i \sim \mathcal{N}(0, \sigma^2)$$
%
% Initially, the problem is solved with an assumed known error variance
% $\sigma^2 = 1$ for all the residuals:
DiscrepancyOptsKnown.Type = 'Gaussian';
DiscrepancyOptsKnown.Parameters = 1;

%% 6.2 Bayesian analysis
%
% The options of the Bayesian analysis are specified with the following
% structure:
BayesOpts.Type = 'Inversion';
BayesOpts.Data = myData;
BayesOpts.Discrepancy = DiscrepancyOptsKnown;
BayesOpts.Solver = Solver;

%%
% Run the Bayesian inversion analysis:
myBayesianAnalysisKnownDisc = uq_createAnalysis(BayesOpts);

%%
% Print out a report of the posterior sample :
uq_print(myBayesianAnalysisKnownDisc)

%%
% Create a graphical representation of the results:
uq_display(myBayesianAnalysisKnownDisc)

%% 7 - BAYESIAN ANALYSIS WITH UNKNOWN MEASUREMENT ERROR

%% 7.1 Discrepancy model
%
% The problem is now solved again with an unknown residual variance 
% parameter $\sigma^2$ for all $N_{out} = 24$ residuals $\varepsilon_i$.
% To infer the error variance, a uniform prior is put on this
% discrepancy parameter:
%
% $$\sigma^2 \sim \mathcal{U}(0,20)$$
%
% Create this distribution as a UQLab INPUT object:
SigmaOpts.Marginals(1).Name = 'Sigma2';
SigmaOpts.Marginals(1).Type = 'Uniform';
SigmaOpts.Marginals(1).Parameters = [0 20];

mySigmaDist = uq_createInput(SigmaOpts);

%%
% Assign the distribution of $\sigma^2$ to the discrepancy options:
DiscrepancyOptsUnknownDisc.Type = 'Gaussian';
DiscrepancyOptsUnknownDisc.Prior = mySigmaDist;

%% 7.2 Bayesian analysis
%
% Update the options of the Bayesian analysis:
BayesOpts.Discrepancy = DiscrepancyOptsUnknownDisc;

%%
% If multiple UQLab INPUT objects are defined, the prior distribution must
% be specified:
BayesOpts.Prior = myPriorDist;

%%
% Run the analysis again with the updated options:
myBayesianAnalysisUnknownDisc = uq_createAnalysis(BayesOpts);

%%
% Print out a report of the results:
uq_print(myBayesianAnalysisUnknownDisc)

%%
% Create a graphical representation of the results:
uq_display(myBayesianAnalysisUnknownDisc)