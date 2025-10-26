%% INVERSION: PREDATOR-PREY MODEL CALIBRATION
%
% In this example, the classical predator-prey equations (or Lotka-Volterra 
% equations) are calibrated against a time series that represents the
% relative population sizes of lynxes and hares in a region.
% The data used to estimate the population sizes over time were published
% in Howard (2009), but were originally collected based on the number of 
% pelts traded by the Hudson Bay Company in the early 20th century.
%
% The example is originally taken from the Stan manual (Carpenter, 2018).
%
% *References*
%
% * Howard, P. (2009). Modeling basics. Lecture Notes for Math 442,
%   Texas A&M University,
%   <http://www.math.tamu.edu/~phoward/m442/modbasics.pdf URL>
%   (last accessed: 13/12/2018).
% * Carpenter, B. (2018). Predator-Prey Population Dynamics:
%   the  Lotka-Volterra model in Stan,
%   <http://mc-stan.org/users/documentation/case-studies/lotka-volterra-predator-prey.html
%   URL> (last accessed: 13/12/2018).

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%%
% Load the measured population size stored in |Data|:
load('uq_Example_BayesianPreyPred.mat')

%% 2 - FORWARD MODEL
%
% The forward model used for calibration is the solution of the 
% Lotka-Volterra differential equations given by:
%
% $$ \frac{\mathrm{d}\,p_{\mathrm{prey}}}{\mathrm{d}\,t}=\alpha p_{\mathrm{prey}} - \beta p_{\mathrm{prey}}p_{\mathrm{pred}}$$
%
% $$ \frac{\mathrm{d}\,p_{\mathrm{pred}}}{\mathrm{d}\,t}=-\gamma p_{\mathrm{pred}} + \delta p_{\mathrm{prey}}p_{\mathrm{pred}}$$
%
% These equations describe the evolution over time $t$ of two populations: 
% the _prey_ $p_{\mathrm{prey}}$ and the _predator_ $p_{\mathrm{pred}}$.
% 
% The forward model computes the population sizes for the duration of
% 21 years, for which measurements $y_{\mathrm{prey}}(t)$ and 
% $y_{\mathrm{pred}}(t)$ are available.
% The model takes as input parameters:
%
% # $\alpha$: growth rate of the prey population
% # $\beta$: shrinkage rate of the prey population (relative to the product
% of the population sizes)
% # $\gamma$: shrinkage rate of the predator population
% # $\delta$: growth rate of the predator population (relative to the product
% of the population sizes)
% # $p_{\mathrm{prey},0}$: initial prey population
% # $p_{\mathrm{pred},0}$: initial predator population
%
% The computation is carried out by the function |uq_predatorPreyModel|
% supplied with UQLab. For every set of input parameters, the function
% returns the population evolution in a 21-year time series.

%%
% Shift the year in the loaded data for consistency with the forward model
% (start from 0):
normYear = Data.year-Data.year(1);

%%
% Specify the forward models as a UQLab MODEL object:
ModelOpts.mHandle = @(x) uq_predatorPreyModel(x,normYear);
ModelOpts.isVectorized = true;

myForwardModel = uq_createModel(ModelOpts);

%% 3 - PRIOR DISTRIBUTION OF THE MODEL PARAMETERS
%
% To encode the available information about the model parameters
% $x_{\mathcal{M}}$ before any experimental observations,
% lognormal prior distributions are put on the parameters as follows:
%
% # $\alpha \sim \mathcal{LN}(\mu_\alpha = 1, \sigma_\alpha = 0.1)$
% # $\beta \sim \mathcal{LN}(\mu_\beta = 5\times10^{-2}, \sigma_\beta = 5\times10^{-3})$
% # $\gamma \sim \mathcal{LN}(\mu_\gamma = 1, \sigma_\gamma = 0.1)$
% # $\delta \sim \mathcal{LN}(\mu_\delta = 5\times10^{-2}, \sigma_\delta = 5\times10^{-3})$
% # $p_{\mathrm{prey},0} \sim \mathcal{LN}(\lambda_{p_{prey}} = \log{(10)}, \zeta_{p_{prey}} = 1)$
% # $p_{\mathrm{pred},0} \sim \mathcal{LN}(\lambda_{p_{pred}} = \log{(10)}, \zeta_{p_{pred}} = 1)$
%
% Specify these prior distributions as a UQLab INPUT object:

PriorOpts.Marginals(1).Name = ('alpha');
PriorOpts.Marginals(1).Type = 'LogNormal';
PriorOpts.Marginals(1).Moments = [1 0.1];

PriorOpts.Marginals(2).Name = ('beta');
PriorOpts.Marginals(2).Type = 'LogNormal';
PriorOpts.Marginals(2).Moments = [0.05 0.005];

PriorOpts.Marginals(3).Name = ('gamma');
PriorOpts.Marginals(3).Type = 'LogNormal';
PriorOpts.Marginals(3).Moments = [1 0.1];

PriorOpts.Marginals(4).Name = ('delta');
PriorOpts.Marginals(4).Type = 'LogNormal';
PriorOpts.Marginals(4).Moments = [0.05 0.005];

PriorOpts.Marginals(5).Name = ('initH');
PriorOpts.Marginals(5).Type = 'LogNormal';
PriorOpts.Marginals(5).Parameters = [log(10) 1]; 

PriorOpts.Marginals(6).Name = ('initL');
PriorOpts.Marginals(6).Type = 'LogNormal';
PriorOpts.Marginals(6).Parameters = [log(10) 1];

myPriorDist = uq_createInput(PriorOpts);

%% 4 - MEASUREMENT DATA
%
% Because the lynx and hare populations have different discrepancy options, 
% the measurement data is stored in two different data structures:  
myData(1).y = Data.hare.'/1000; %in 1000
myData(1).Name = 'Hare data';
myData(1).MOMap = 1:21; % Output ID

myData(2).y = Data.lynx.'/1000; %in 1000
myData(2).Name = 'Lynx data';
myData(2).MOMap = 22:42; % Output ID

%% 5 - DISCREPANCY MODEL
%
% To infer the discrepancy variance, lognormal priors are put on the
% discrepancy parameters:
%
% * $\sigma^2_{\mathrm{prey}} \sim \mathcal{LN}(\lambda_{\sigma^2_\mathrm{prey}} = -1, \zeta_{\sigma^2_\mathrm{prey}} = 1)$
% * $\sigma^2_{\mathrm{pred}} \sim \mathcal{LN}(\lambda_{\sigma^2_\mathrm{pred}} = -1, \zeta_{\sigma^2_\mathrm{pred}} = 1)$
%
% Specify these distributions in UQLab separately as two INPUT objects:
SigmaOpts.Marginals(1).Name = 'Sigma2L';
SigmaOpts.Marginals(1).Type = 'Lognormal';
SigmaOpts.Marginals(1).Parameters = [-1 1];

SigmaDist1 = uq_createInput(SigmaOpts);

SigmaOpts.Marginals(1).Name = 'Sigma2H';
SigmaOpts.Marginals(1).Type = 'Lognormal';
SigmaOpts.Marginals(1).Parameters = [-1 1];

SigmaDist2 = uq_createInput(SigmaOpts);

%%
% Assign these distributions to the discrepancy model options:
DiscrepancyOpts(1).Type = 'Gaussian';
DiscrepancyOpts(1).Prior = SigmaDist1;
DiscrepancyOpts(2).Type = 'Gaussian';
DiscrepancyOpts(2).Prior = SigmaDist2;

%% 6 - BAYESIAN ANALYSIS
%
%% 6.1 MCMC solver options
%
% To sample from the posterior distribution, the affine invariant ensemble
% algorithm is chosen, with $400$ iterations and $100$ parallel chains:
Solver.Type = 'MCMC';
Solver.MCMC.Sampler = 'AIES';
Solver.MCMC.Steps = 400;
Solver.MCMC.NChains = 100;

%%
% Enable progress visualization during iteration for the initial prey
% and predator populations (parameters 5 and 6, respectively).
% Update the plots every $40$ iterations:
Solver.MCMC.Visualize.Parameters = [5 6];
Solver.MCMC.Visualize.Interval = 40;

%% 6.2 Posterior sample generation
%
% The options of the Bayesian analysis are gathered within a single
% structure with fields: 
BayesOpts.Type = 'Inversion';
BayesOpts.Name = 'Bayesian model';
BayesOpts.Prior = myPriorDist;
BayesOpts.Data = myData;
BayesOpts.Discrepancy = DiscrepancyOpts;
BayesOpts.Solver = Solver;

%%
% Perform and store in UQLab the Bayesian inversion analysis:
myBayesianAnalysis = uq_createAnalysis(BayesOpts);

%%
% Print out a report of the results:
uq_print(myBayesianAnalysis)

%% 6.3 Posterior sample post-processing
%
% Diagnose the quality of the results,
% create a trace plot of the first parameter:
uq_display(myBayesianAnalysis, 'trace', 1)

%%
% From the plots, one can see that several chains have not converged yet.
% From the trace plot, the non-converged chains are all characterized by a
% final value $x_1^{(T)}>0.8$:
badChainsIndex = squeeze(myBayesianAnalysis.Results.Sample(end,1,:) > 0.8);

%%
% These chains can be removed from the sample through post-processing. 
% Additionally, draw a sample of size $10^3$ from the prior and posterior
% predictive distributions: 
uq_postProcessInversionMCMC(myBayesianAnalysis,...
                        'badChains', badChainsIndex,...
                        'prior', 1000,...
                        'priorPredictive', 1000,...
                        'posteriorPredictive', 1000);

%%
% *Note*: sampling prior predictive samples requires new
% model evaluations

%%
% Display the post processed results:
uq_display(myBayesianAnalysis)
