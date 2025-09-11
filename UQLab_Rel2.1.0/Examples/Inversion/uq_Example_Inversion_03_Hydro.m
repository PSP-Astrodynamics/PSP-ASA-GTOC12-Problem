%% INVERSION: HYDROLOGICAL MODEL CALIBRATION
%
% In this example, the HYMOD conceptual watershed model is calibrated
% using measured discharge records from the Leaf River $(1950\,\mathrm{km^2})$
% watershed in Mississippi between January 1, 1952 and September 30, 1954.
% The calibration is carried out with a custom additive discrepancy and 
% solved using an MCMC sampler.
%
% The problem setup of this example is adapted from Example 4 of the DREAM
% Suite developed by Miroslav Sejna and Jasper Vrugt. For details, see:
% PC-Progress. (2016). DREAM Suite version 1: User Manual, 
% <http://www.pc-progress.com/en/onlinehelp/dream1/DREAM_Suite.html URL>
% (last accessed: 14/02/2019). 

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

%% 2 - FORWARD MODEL
%
% The forward model used in the calibration is the HYMOD watershed model.
% It models the discharge using five parameters:
%
% # $c_{\mathrm{max}}$: maximum interception (mm)
% # $b_{\mathrm{exp}}$: soil water storage capacity (-)
% # $\alpha$: maximum percolation rate (-)
% # $r_s$: recession constant slow-flow reservoir (-)
% # $r_q$: recession constant fast-flow reservoir (-)
%
% The HYMOD model has been implemented in the function
% |uq_hymod(X,ModelConstants)| supplied with UQLab. The function
% evaluates the model using the input parameters gathered in the columns
% of the matrix |X| following the order above and constant parameters 
% given in the structure |ModelConstants|.
%
% Define the forward model as a UQLab MODEL object:
ModelOpts.Name = 'HYMOD Model';
ModelOpts.mHandle = @(x) uq_hymod(x,ModelSetup);
ModelOpts.isVectorized = true;

myForwardModel = uq_createModel(ModelOpts);

%%
% Using this setup, the HYMOD model predicts a $1 \times 731$ time series 
% of the watershed discharge. For details on the HYMOD model, see:
% Boyle, D. P. (2001). Multicriteria calibration of hydrologic models.
% Ph.D. Dissertation. University of Arizona, 2001. <https://repository.arizona.edu/handle/10150/290657?show=full URL>
% (last accessed: 14/02/2019)

%% 3 - PRIOR DISTRIBUTION OF THE MODEL PARAMETERS
%
% Uniform prior distributions are given to the parameters as follows:
%
% # $c_{\mathrm{max}} \sim \mathcal{U}(1, 500)$
% # $b_{\mathrm{exp}} \sim \mathcal{U}(0.1, 2)$
% # $\alpha \sim \mathcal{U}(0.1, 0.99)$
% # $r_s \sim \mathcal{U}(0, 0.1)$
% # $r_q \sim \mathcal{U}(0.1, 0.99)$

%%
% Specify these distributions as a UQLab INPUT object:
PriorOpts.Name = 'Prior distribution on HYMOD parameters';

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

myPriorDist = uq_createInput(PriorOpts);

%% 4 - MEASUREMENT DATA
%
% The measured discharge record of the Leaf river is stored in the |myData|
% structure:
myData.y = Data; % (m)
myData.Name = 'Leaf river discharge';

%% 5 - DISCREPANCY MODEL
%
% Models for the discrepancy $\varepsilon$ between the forward model and
% the data are specified via the discrepancy options.
% Here, the discrepancy for each forward model output are chosen to be
% independent and identically distributed Gaussian random variables:
%
% $$\varepsilon_i \sim \mathcal{N}(0,\sigma^2)$$
%
% with mean $0$ and an unknown variance $\sigma^2$.
% To infer $\sigma^2$, a uniform prior is put
% on this discrepancy parameter:
%
% $$\sigma^2 \sim \mathcal{U}(0,300).$$
%
% Specify this distribution as an INPUT object:
SigmaOpts.Marginals(1).Name = 'sigma2';
SigmaOpts.Marginals(1).Type = 'Uniform';
SigmaOpts.Marginals(1).Parameters = [0 300];

mySigmaDist = uq_createInput(SigmaOpts);

%%
% Assign the distribution of $\sigma^2$ to the discrepancy options:
DiscrepancyOpts.Type = 'Gaussian';
DiscrepancyOpts.Prior = mySigmaDist;

%% 6 - BAYESIAN ANALYSIS

%% 6.1 Solver options
%
% To sample directly from the posterior distribution,
% the affine invariant ensemble algorithm is employed for this example,
% using $100$ parallel chains, each with $200$ iterations:
Solver.Type = 'MCMC';
Solver.MCMC.Sampler = 'AIES';
Solver.MCMC.NChains = 100;
Solver.MCMC.Steps = 200;

%%
% Switch on a visualization during iterations for parameters 
% $c_{\mathrm{max}}$ and $\alpha$ (the first and third parameters) and 
% update the plots every $40$ iterations:
Solver.MCMC.Visualize.Parameters = [1 3];
Solver.MCMC.Visualize.Interval = 40;

%% 6.2 Posterior sample generation
% The options for the Bayesian analysis are specified with the following
% structure:
BayesOpts.Type = 'Inversion';
BayesOpts.Name = 'Bayesian model';
BayesOpts.Prior = myPriorDist;
BayesOpts.Data = myData;
BayesOpts.Discrepancy = DiscrepancyOpts;
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

%% 6.3 Posterior sample post-processing
%
% A sample generated by an MCMC algorithm often requires post-processing.
% In UQLab, this can be done with the |uq_postProcessInversionMCMC| function:
uq_postProcessInversionMCMC(myBayesianAnalysis, 'burnIn', 0.75);
   
%%
% This command is automatically called with its default options after each
% analysis. In the present case, however, custom options have to be
% specified where the first three quarter sample points are removed 
% (instead of the default first half).

%%
% Display the post-processed results:
uq_display(myBayesianAnalysis,'scatterplot','all')