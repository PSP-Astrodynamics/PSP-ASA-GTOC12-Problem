%% INVERSION: CALIBRATION OF MULTIPLE FORWARD MODELS
%
% This example shows how multiple computational models can be calibrated 
% simultaneously, a process known in some fields as joint inversion. 
% In this example, two different sets of deformation measurements of the
% same specimen are used to calibrate its Young's  modulus $E$, by
% subjecting it to an uncertain distributed load $p$ and to an uncertain
% point load $P$.
%
% The first set of measurements refers to the mid-span deflection of the
% simply supported specimen under the distributed load $p$, while and the
% second set refers to its elongation under the constant load $P$.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - FORWARD MODELS
%
% The first forward model is the deflection of the beam at the mid-span 
% location ($V$), which reads:
%
% $$ V = \frac{ 5 p L^4 }{32 E b h^3}$$
%
% This computation is carried out by the function
% |uq_SimplySupportedBeam(X)| supplied with UQLab.
% The function evaluates the input parameters given in the columns 
% of the matrix |X| in the following order:
%
% # $b$: beam width $(m)$
% # $h$: beam height $(m)$
% # $L$: beam length $(m)$
% # $E$: Young's modulus $(Pa)$
% # $p$: uniform load $(N/m)$

%%
% The simply supported beam problem is shown in the following figure:
uq_figure
[I,~] = imread('SimplySupportedBeam.png');
image(I)
axis equal
set(gca, 'visible', 'off')

%%
% Create a UQLab MODEL object and store it in a structure array. 
% In addition, specify a |PMap| vector to specify which prior model
% parameters are to be passed to the first forward model:
ModelOpts1.Name = 'Beam mid-span deflection';
ModelOpts1.mFile = 'uq_SimplySupportedBeam';

forwardModels(1).Model = uq_createModel(ModelOpts1);
forwardModels(1).PMap = [1 2 3 4 5];

%%
% The second forward model is the elongation of a prismatic beam ($U$),
% which is computed by:
%
% $$ U = \frac{PL}{Ebh}$$
% 
% with an additional parameter:
%
% * $P$: Point load $(N)$

%%
% The beam elongation problem is shown in the following figure:
uq_figure
[I,~] = imread('ElongationBeam.png');
image(I)
axis equal
set(gca, 'visible', 'off')

%%
% Create a UQLab MODEL object and store it in a structure array.
% The model in this case is directly defined with a string:
ModelOpts2.Name = 'Beam elongation';
ModelOpts2.mString = 'X(:,5).*X(:,3)./(X(:,1).*X(:,2).*X(:,4))';
ModelOpts2.isVectorized = true;
forwardModels(2).Model = uq_createModel(ModelOpts2);

%%
% The model shares most inputs with the previous, but instead of the
% uniform load $p$ (parameter |5|), it uses the point load $P$ 
% (parameter |6|). This is specified with the |PMap| vector:
forwardModels(2).PMap = [1 2 3 4 6];

%% 3 - PRIOR DISTRIBUTION OF THE MODEL PARAMETERS
%
% The prior distribution of the model parameter $E$ and the uncertain loads
% $p$ and $P$ are given by:
%
% * $E \sim \mathcal{LN}(\mu_E = 30\times10^9, \sigma_E = 4.5\times10^9)~(N/m^2)$
% * $p \sim \mathcal{N}(\mu_p = 12\times10^3, \sigma_p = 3\times10^3)~(N/m)$
% * $P \sim \mathcal{LN}(\mu_P = 50\times10^3, \sigma_P = 10^3)~(N)$
%
% The parameters $b$, $h$, and $L$, on the other hand,
% are fixed as follows:
%
% * $b = 0.15~(m)$
% * $h = 0.3~(m)$
% * $L = 5~(m)$
%
% Gather these distributions in a UQLab INPUT object:
PriorOpts.Marginals(1).Name = 'b'; % beam width
PriorOpts.Marginals(1).Type = 'Constant';
PriorOpts.Marginals(1).Parameters = 0.15; % (m)

PriorOpts.Marginals(2).Name = 'h'; % beam height
PriorOpts.Marginals(2).Type = 'Constant';
PriorOpts.Marginals(2).Parameters = 0.3; % (m)

PriorOpts.Marginals(3).Name = 'L'; % beam length
PriorOpts.Marginals(3).Type = 'Constant';
PriorOpts.Marginals(3).Parameters = 5; % (m)

PriorOpts.Marginals(4).Name = 'E'; % Young's modulus
PriorOpts.Marginals(4).Type = 'Lognormal';
PriorOpts.Marginals(4).Moments = [30 4.5]*1e9 ; % (N/m^2)

PriorOpts.Marginals(5).Name = 'p'; % uniform load
PriorOpts.Marginals(5).Type = 'Lognormal';
PriorOpts.Marginals(5).Moments = [12e3 3e3]; % (N/m)

PriorOpts.Marginals(6).Name = 'P'; % point load
PriorOpts.Marginals(6).Type = 'Lognormal';
PriorOpts.Marginals(6).Moments = [50e3 1e3] ; % (N)

myPriorDist = uq_createInput(PriorOpts);

%% 4 - MEASUREMENT DATA
%
% In the case of multiple forward models, and therefore different types of
% data, it is necessary to define the full |MOMap| array to identify which
% model output needs to be compared with which data set:

% Data group 1
myData(1).y = [12.84; 13.12; 12.13; 12.19; 12.67]/1000;% (m)
myData(1).Name = 'Beam mid-span deflection';
myData(1).MOMap = [ 1;... % Model ID
                    1];   % Output ID
% Data group 2
myData(2).y = [0.235; 0.236; 0.229]/1000;% (m)
myData(2).Name = 'Beam elongation';
myData(2).MOMap = [ 2;... % Model ID
                    1];   % Output ID

%% 5 - DISCREPANCY MODEL
%
% To infer the discrepancy variance, uniform priors are put on the
% discrepancy parameters:
%
% * $\sigma^2_{\mathrm{1}} \sim \mathcal{U}(0, 10^{-6})~(m^2)$
% * $\sigma^2_{\mathrm{2}} \sim \mathcal{U}(0, 10^{-10})~(m^2)$
%
% Create two UQLab INPUT objects based on these distributions:
SigmaOpts.Marginals(1).Name = 'Sigma2V';
SigmaOpts.Marginals(1).Type = 'Uniform';
SigmaOpts.Marginals(1).Parameters = [0 1e-6];% (m^2)

SigmaDist1 = uq_createInput(SigmaOpts);

SigmaOpts.Marginals(1).Name = 'Sigma2U';
SigmaOpts.Marginals(1).Type = 'Uniform';
SigmaOpts.Marginals(1).Parameters = [0 1e-10];% (m^2)

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
% algorithm is employed in this example, with $200$ iterations
% and $100$ parallel chains:
Solver.Type = 'MCMC';
Solver.MCMC.Sampler = 'AIES';
Solver.MCMC.Steps = 200;
Solver.MCMC.NChains = 100;

%% 6.2 Posterior sample generation
%
% The options of the Bayesian analysis are specified with the following
% structure, where the |forwardModels| structure array is passed to the 
% |BayesOpts.ForwardModel| field:
BayesOpts.Type = 'Inversion';
BayesOpts.Name = 'Bayesian model1';
BayesOpts.Prior = myPriorDist;
BayesOpts.ForwardModel = forwardModels;
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