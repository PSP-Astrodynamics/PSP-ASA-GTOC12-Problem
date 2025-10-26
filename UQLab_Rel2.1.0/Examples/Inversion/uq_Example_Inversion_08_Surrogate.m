%% INVERSION: SURROGATE MODEL ACCELERATED CALIBRATION
%
% In this example, it is shown how a surrogate model can be constructed 
% and then used instead of the original forward model in a Bayesian inversion
% analysis. For a computationally expensive forward model, this approach
% can yield considerable time savings in the analysis. 
%
% The problem considered here is similar to the one in
% |uq_Example_Inversion_01_Beam|. The inversion analysis is rerun and
% compared to an analysis using a polynomial chaos expansion (PCE) 
% surrogate of the full computational model. 

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
% Define the forward model as a MODEL object using the function
% |uq_SimplySupportedBeam(X)|:
ModelOpts.mFile = 'uq_SimplySupportedBeam';
ModelOpts.isVectorized = true;

myForwardModel = uq_createModel(ModelOpts);

%%
% For more information about the function |uq_SimplySupportedBeam(X)|,
% refer to |uq_Example_Inversion_01_Beam|.

%% 3 - PRIOR DISTRIBUTION OF THE MODEL PARAMETERS
%
% The prior information about the model parameters is gathered in a
% probabilistic model that includes both known (constant) and unknown
% parameters. 

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
PriorOpts.Marginals(4).Moments = [30e9 4.5e9];   % (N/m^2)

PriorOpts.Marginals(5).Name = 'p';               % uniform load 
PriorOpts.Marginals(5).Type = 'Gaussian';
PriorOpts.Marginals(5).Moments = [12e3 6e2]; % (N/m)

myPriorDist = uq_createInput(PriorOpts);

%% 4 - SURROGATE MODEL
% Use polynomial chaos expansions (PCE) to construct a surrogate model of
% |myForwardModel|:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'PCE';
MetaOpts.ExpDesign.NSamples = 50;
mySurrogateModel = uq_createModel(MetaOpts);

%%
% With just 50 model evaluations, the PCE is extremely accurate
% and has a leave-one-out cross-validation error
% of $\varepsilon_{\mathrm{LOO}}\approx 10^{-7}$.

%% 5 - MEASUREMENT DATA
%
% The measurement data consists of $N = 5$ independent measurements of 
% the beam mid-span deflection.
% The data is stored in the column vector |y|:
myData.y = [12.84; 13.12; 12.13; 12.19; 12.67]/1000;  % (m)
myData.Name = 'Mid-span deflection';

%% 6 - BAYESIAN ANALYSIS
%
% The options of the Bayesian inversion analysis are specified with
% the following structure:
BayesOpts.Type = 'Inversion';
BayesOpts.Data = myData;

%%
% To use the original forward model |myForwardModel| in the analysis,
% set the following option:
BayesOpts.ForwardModel.Model = myForwardModel;

%%
% Run the Bayesian inversion analysis:
myBayesianAnalysis_fullModel = uq_createAnalysis(BayesOpts);

%%
% Print out a report of the results:
uq_print(myBayesianAnalysis_fullModel)

%%
% For comparison, the analysis is now rerun using the surrogate model
% |mySurrogateModel| in lieu of the original |myForwardModel|:
BayesOpts.ForwardModel.Model = mySurrogateModel;

%%
% Run the Bayesian inversion analysis:
myBayesianAnalysis_surrogateModel = uq_createAnalysis(BayesOpts);

%%
% Print out a report of the results:
uq_print(myBayesianAnalysis_surrogateModel)
uq_display(myBayesianAnalysis_surrogateModel)

%%
% Comparing |myBayesianAnalysis_fullModel| and
% |myBayesianAnalysis_surrogateModel| it can be seen that the results are
% practically identical. The small differences come from the randomness of
% the MCMC algorithms.

%%
% The number of original forward model calls in MCMC with the full model
% was $N = 30{,}000$ compared to the $N = 50$ model evaluations necessary
% to compute the PCE surrogate. In cases where the original forward model
% is computationally expensive, accelerating MCMC with surrogate models
% result in significant reduction of the total computational costs.
%
% In this example, a PCE surrogate was employed, but generally any 
% surrogate model available in UQLab (e.g., Kriging, LRA, SVR) can be used.