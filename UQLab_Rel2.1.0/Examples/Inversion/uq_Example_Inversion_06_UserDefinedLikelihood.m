%% INVERSION: USER-DEFINED LIKELIHOOD FUNCTION
%
% This example shows how to provide a user-defined likelihood function.
% The forward model used in this example is the same as the one used in the
% |uq_Example_Inversion_03_Hydro| example.
% In this case, a user-defined likelihood function is used to calibrate
% the time-dependent HYMOD model while taking into account dependence
% between time points in the time series data. 

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%%
% Load the model constants |ModelSetup| and |Data|:
load('uq_Example_BayesianHydro')

%% 2 - CUSTOM LIKELIHOOD FUNCTION
%
% The custom likelihood function (provided in the file
% |uq_customLogLikelihood.m|), makes
% use of the same HYMOD conceptual watershed model shown in
% |uq_Example_Inversion_03_Hydro|.
% The likelihood represents a complex error model with covariances
% between error parameters. 

%%
% The Bayesian inversion module expects two arguments |params| and |y|
% for the user-defined likelihood functions that correspond to the model
% parameters and the data, respectively.
% Create a function handle to the function |uq_customLogLikelihood|
% as a wrapper with the two arguments:
myLogLikelihood = @(params,y) uq_customLogLikelihood(params,...
    y, ModelSetup);

%%
% See the APPENDIX - LIKELIHOOD FUNCTION at the end of this example script
% for more details on this function.

%% 3 - PRIOR DISTRIBUTION OF THE MODEL PARAMETERS
%
% Uniform prior distributions are given to the parameters as follows:
%
% * $c_{\mathrm{max}} \sim \mathcal{U}(1, 500)$
% * $b_{\mathrm{exp}} \sim \mathcal{U}(0.1, 2)$
% * $\alpha \sim \mathcal{U}(0.1, 0.99)$
% * $r_s \sim \mathcal{U}(0, 0.1)$
% * $r_q \sim \mathcal{U}(0.1, 0.99)$
%
% When user-defined likelihood functions are used, it is also necessary to
% specify the prior distribution of the parameters of the discrepancy model
% here. The current likelihood function has two discrepancy parameters:
% $\sigma^2$ and $\theta$, with the following prior distributions:
%
% * $\sigma^2 \sim \mathcal{U}(0, 300)$
% * $\theta \sim \mathcal{U}(0, 40)$
%
% See the APPENDIX - LIKELIHOOD FUNCTION at the end of this script for
% details on the user-defined likelihood function and the corresponding
% discrepancy model parameters.
%
% Specify these distributions as a UQLab INPUT object:
PriorOpts.Name = 'Prior distribution on HYMOD parameters';

% Model parameters
PriorOpts.Marginals(1).Name = 'cmax'; % maximum interception
PriorOpts.Marginals(1).Type = 'Uniform';
PriorOpts.Marginals(1).Parameters = [1 500]; % (mm)

PriorOpts.Marginals(2).Name = 'bexp'; % soil water storage capacity
PriorOpts.Marginals(2).Type = 'Uniform';
PriorOpts.Marginals(2).Parameters = [0.1 2]; % (-)

PriorOpts.Marginals(3).Name = 'alpha'; % maximum percolation rate
PriorOpts.Marginals(3).Type = 'Uniform';
PriorOpts.Marginals(3).Parameters = [0.1 0.99]; % (-)

PriorOpts.Marginals(4).Name = 'rs'; % recession constant slow-flow
PriorOpts.Marginals(4).Type = 'Uniform';
PriorOpts.Marginals(4).Parameters = [0 0.1]; % (-)

PriorOpts.Marginals(5).Name = 'rq'; % recession constant fast-flow 
PriorOpts.Marginals(5).Type = 'Uniform';
PriorOpts.Marginals(5).Parameters = [0.1 0.99]; % (-)

% Discrepancy parameters
PriorOpts.Marginals(6).Name = 'sigma2'; % variance
PriorOpts.Marginals(6).Type = 'Uniform';
PriorOpts.Marginals(6).Parameters = [0 300]; % (m^2)

PriorOpts.Marginals(7).Name = 'theta'; % correlation length
PriorOpts.Marginals(7).Type = 'Uniform';
PriorOpts.Marginals(7).Parameters = [0 40]; % (d)

myPriorDist = uq_createInput(PriorOpts);

%% 4 - MEASUREMENT DATA
%
% The measured discharge record of the Leaf river is stored in the |myData|
% structure. To decrease the computational time, only every 10th data point
% is used:
myData.y.meas = Data(1:10:end); % (m)
myData.y.time = Time(1:10:end); % (d)
myData.Name = 'Leaf river discharge';

%% 5 - BAYESIAN ANALYSIS

%% 5.1 Solver options
%
% To sample directly from the posterior distribution,
% the affine invariant ensemble algorithm is employed for this example,
% using $100$ parallel chains, each with $200$ iterations:
Solver.Type = 'MCMC';
Solver.MCMC.Sampler = 'AIES';
Solver.MCMC.NChains = 100;
Solver.MCMC.Steps = 200;

%%
% Visually display the progress of the MCMC during iterations for
% parameters $c_{\mathrm{max}}$ and $\alpha$ (parameter |1| and |3|,
% respectively) and update the plots every $20$ iterations: 
Solver.MCMC.Visualize.Parameters = [1 3];
Solver.MCMC.Visualize.Interval = 20;

%% 5.2 Posterior sample generation
%
% Gather the options in a single structure
BayesOpts.Type = 'Inversion';
BayesOpts.Name = 'Bayesian model';
BayesOpts.Prior = myPriorDist;
BayesOpts.Data = myData;
BayesOpts.LogLikelihood = myLogLikelihood;
BayesOpts.Solver = Solver;

%%
% Run the Bayesian inversion analysis:
myBayesianAnalysis = uq_createAnalysis(BayesOpts);

%%
% Print out a report of the results:
uq_print(myBayesianAnalysis)

%%
% Create a graphical representation of the results:
uq_display(myBayesianAnalysis)

%% APPENDIX - LIKELIHOOD FUNCTION
% 
% The presented user-defined likelihood function is provided in the file 
% |uq_customLogLikelihood.m|.
%
% It implements a discrepancy model that assumes correlations between the 
% individual model outputs. It assumes that the discrepancy $\mathbf{\varepsilon}$ 
% is distributed according to:
%
% $$\mathbf{\varepsilon} \sim \mathcal{N}(0,\mathbf{\Sigma})$$
%
% with the covariance matrix $\mathbf{\Sigma}$ given by:
%
% $$\Sigma_{i,j} = \sigma^2 R(t_i,t_j,\theta)$$
%
% where $\sigma^2$ is the discrepancy variance; $t_i,t_j$ are a pair of
% time points; and $$R(t_i,t_j,\theta)$ is an exponential correlation
% function given by:
%
% $$R(t_i,t_j,\theta) = \exp\left(-\frac{\vert t_j-t_i\vert}{\theta}\right)$$
%
% where $\theta$ is the discrepancy correlation length.