%% INVERSION: SIMPLE BEAM CALIBRATION
% 
% In this example, the measured deflections of a simply supported beam 
% under a uniform load $p$ are used to calibrate the Young's Modulus $E$
% of the beam material. Basic uncertainty on the applied $p$ is assumed.
% The calibration is carried out with default
% model/data discrepancy options.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - FORWARD MODEL
%
% The simply supported beam problem is shown in the following figure:
uq_figure
[I,~] = imread('SimplySupportedBeam.png');
image(I)
axis equal
set(gca, 'visible', 'off')

%% 
% The forward model computes the deflection of the beam $V$
% at mid-span location, which reads:
%
% $$ V = \frac{ 5 p L^4 }{32 E b h^3}$$
%
% This computation is carried out by the function
% |uq_SimplySupportedBeam(X)| supplied with UQLab.
% The input variables of this function are gathered into the $N \times M$
% matrix |X|, where $N$ and $M$ are the number of realizations
% input variables, respectively.
% The variables are given in the following order:
%
% # $b$: beam width $(m)$
% # $h$: beam height $(m)$
% # $L$: beam length $(m)$
% # $E$: Young's modulus $(Pa)$
% # $p$: uniform load $(N/m)$

%%
% Define the forward model as a UQLab MODEL object:
ModelOpts.mFile = 'uq_SimplySupportedBeam';
ModelOpts.isVectorized = true;

myForwardModel = uq_createModel(ModelOpts);

%% 3 - PRIOR DISTRIBUTION OF THE MODEL PARAMETERS
%
% The prior information about the model parameters is gathered in a
% probabilistic model that includes both known and unknown parameters.
%
% The geometrical dimensions $b$ (beam width), $h$ (beam height) and $L$
% (beam length) are perfectly known:
%
% * $b = 0.15~(m)$ 
% * $h=0.3~(m)$
% * $L = 5~(m)$
% 
% The applied load $p$ is known up to some Gaussian measurement noise. 
% The Young's modulus $E$, target of the calibration experiment, is
% given a lognormal prior distribution:
%
% * $p \sim \mathcal{N}(\mu_p = 12\times10^3, \sigma_p = 6\times10^2)~(N/m)$
% * $E \sim \mathcal{LN}(\mu_E = 30\times10^9, \sigma_E = 4.5\times10^9)~(N/m^2)$
%
% Specify these distributions as a UQLab INPUT object:
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

%%
% Constant model parameters in the prior indicate certainty about their
% value. These parameters will not be calibrated.

%% 4 - MEASUREMENT DATA
%
% The measurement data consists of $N = 5$ independent measurements of 
% the beam mid-span deflection.
% The data is stored in the column vector |y|:
myData.y = [12.84; 13.12; 12.13; 12.19; 12.67]/1000; % (m)
myData.Name = 'Mid-span deflection';

%% 5 - DISCREPANCY MODEL
%
% By default, the Bayesian calibration module of UQLab assumes
% an independent and identically distributed
% discrepancy $\varepsilon\sim\mathcal{N}(0,\sigma^2)$ between
% the observations and the predictions for each data.
% The variance $\sigma^2$ of the discrepancy term is by default
% given a uniform prior distribution:
% 
% $$ \pi(\sigma^2) = \mathcal{U}(0,\mu_{\mathcal{Y}}^2), \quad
% \mathrm{with} \quad  \mu_{\mathcal{Y}} = \frac{1}{N}\sum_{j=1}^{N}y_{j}
% \quad (\mathrm{here~equal~to}~0.01259)$$

%% 6 - BAYESIAN ANALYSIS
%
% The options of the Bayesian analysis are specified with the following
% structure:
BayesOpts.Type = 'Inversion';
BayesOpts.Data = myData;

%%
% Run the Bayesian inversion analysis:
myBayesianAnalysis = uq_createAnalysis(BayesOpts);
%%
% Print out a report of the results:
uq_print(myBayesianAnalysis)

%%
% Create a graphical representation of the results:
uq_display(myBayesianAnalysis)