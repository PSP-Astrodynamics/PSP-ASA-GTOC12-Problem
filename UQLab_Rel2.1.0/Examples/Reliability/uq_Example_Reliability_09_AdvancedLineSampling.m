%% RELIABILITY: LINE SAMPLING EXAMPLE
%
% This example showcases the application of the line sampling method for
% reliability analysis in UQLab on a two-dimensional example
%
% For details, see:
% Chao Dang, Marcos A. Valdebenito, Jingwen Song, Pengfei Wei,
% Michael Beer.
% Estimation of small failure probabilities by partially 
% Bayesian active learning line sampling: Theory and algorithm,
% Computer Methods in Applied Mechanics and Engineering, Volume 412, 2023,
% https://doi.org/10.1016/j.cma.2023.116068.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL
%
% The example function is defined as:
%
% $$5 - X_2 + 0.01 X_1^3 + \sin(X_1)$$
%
% where $\mathbf{X} = \{X_1, X_2\}$.
%
% Create a limit state function model using a string,
% written below in a vectorized operation:
ModelOpts.mString = '5 - X(:,2) + 0.01 * X(:,1).^3 + sin(X(:,1))';
ModelOpts.isVectorized = true;

myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of two independent standard 
% Gaussian random variables:
%
% $$X_1 \sim \mathcal{N}(0, 1), \; X_2 \sim \mathcal{N}(0, 1)$$
%
InputOpts.Marginals = uq_StdNormalMarginals(2);

%%
% Create an INPUT object based on the specified marginals:
myInput = uq_createInput(InputOpts);

%% 4 - RELIABILITY ANALYSIS WITH LINE SAMPLING
%
% In this Section, we test the following methods:
%
% * Line Sampling
% * Line Sampling with without adapation of the direction
% * Line Sampling with with polynomial interpolation

%% 4.1 Line Sampling 
% First, line sampling is performed using the standard UQLab settings for
% the Direction and the RootFinder:
% 
% * LSOpts.LS.RootFinder.Type = 'Newton'
%
% * LSOpts.LS.Direction.Initial = 'GradOrigin'
% * LSOpts.LS.Direction.Adaptive = true
%
% Select the Reliability module and the Line Sampling (LS) method:
LSOpts.Type = 'Reliability';
LSOpts.Method = 'LS';

%% Number of Lines
% Specify the maximum sample size, the size of the batch,
% and the target coefficient of variation:
LSOpts.LS.MaxLines = 1000;
LSOpts.LS.BatchSize = 50;
LSOpts.LS.TargetCoV = 0.05;

%%
% Run the Line Sampling simulation:
myLSAnalysis = uq_createAnalysis(LSOpts);

%%
% Print out a report of the results:
uq_print(myLSAnalysis)

%% 
% Visualize the results of the analysis:
uq_display(myLSAnalysis)

%% 4.2 Line Sampling without direction adaptation
% Now, line sampling is performed using a non-adaptive direction initially
% determined using FORM and spline interpolation as the root finder.
%
% Select the Reliability module and the Line Sampling (LS) method:
LSOpts2.Type = 'Reliability';
LSOpts2.Method = 'LS';

%% RootFinder
% Set the root finder to spline interpolation method:
LSOpts2.LS.RootFinder.Type = 'spline';

% Note: by default, spline interpolation is performed using the following
% points along each line:
LSOpts2.LS.RootFinder.WayPoints = 2:7 ;

%% Direction
% Select FORM for the initial direction:
LSOpts2.LS.Direction.Initial = 'FORM';
% Set the number of maximum FORM iterations using the FORM options:
LSOpts2.FORM.MaxIterations = 5;

% Disable the adaptation of the direction:
LSOpts2.LS.Direction.Adaptive = false;

%% Number of Lines
% Specify the maximum sample size, the size of the batch,
% and the target coefficient of variation:
LSOpts2.LS.MaxLines = 1000;
LSOpts2.LS.BatchSize = 50;
LSOpts2.LS.TargetCoV = 0.05;

%%
% Run the Line Sampling simulation:
myLSAnalysis2 = uq_createAnalysis(LSOpts2);

%%
% Print out a report of the results:
uq_print(myLSAnalysis2)

%% 
% Visualize the results of the analysis:
uq_display(myLSAnalysis2)

%% 4.3 Line Sampling with iterative root finding
% Finally, adaptive line sampling is perfomed with an iterative root
% finding algorithm, Newton's method.
%
% Select the Reliability module and the Line Sampling (LS) method:
LSOpts3.Type = 'Reliability';
LSOpts3.Method = 'LS';

%% Root Finder
% Line sampling with polynomial interpolation:
LSOpts3.LS.RootFinder.Type = 'Polynomial';

% Note: by default, polynomial interpolation is performed using the 
% following points along each line:
LSOpts3.LS.RootFinder.WayPoints = [2,5,7];

%%
% Run the Line Sampling simulation:
myLSAnalysis3 = uq_createAnalysis(LSOpts3);

%%
% Print out a report of the results:
uq_print(myLSAnalysis3)

%% 
% Visualize the results of the analysis:
uq_display(myLSAnalysis3)

%% 5 - RELIABILITY ANALYSIS WITH BAYESIAN LINE SAMPLING
%
% In this Section, we test the following Bayesian line sampling methods:
%
% * Bayesian Line Sampling with upper bound of variance
% * Bayesian Line Sampling with true variance


%% 5.1 Bayesian Line Sampling using the upper bound of the variance
% First, Bayesian line sampling is performed using the upper bound as the
% estimation for the variance and learning function.
% Additionally, a linear trend is used for the Kriging model for beta.
%
% Select BLS as the reliability analysis method:
BLSOpts.Type = 'Reliability';
BLSOpts.Method = 'BLS';

%% Simulation Settings for the MC estimation of moments
% Specify the maximum sample size, the size of the batch,
% and the target coefficient of variation for the MC estimation of the
% moments:
BLSOpts.Simulation.MaxSampleSize = 1e6;
BLSOpts.Simulation.BatchSize = 1e5;
BLSOpts.Simulation.TargetCoV = 0.05;

%%
% Specify the learning function:
BLSOpts.BLS.LearningFunction = 'upper variance';

%%
% Set stopping CoV of the Bayesian active learning:
BLSOpts.BLS.ConvCoV = 0.05;

%%
% Specify the options of the Kriging model:
BLSOpts.BLS.Kriging.Trend.Type = 'linear';

%%
% Enable verbose display:
BLSOpts.Display = 5;

%%
% Run the BLS analysis
myBLSAnalysis = uq_createAnalysis(BLSOpts);

%%
% Print out a report of the results:
uq_print(myBLSAnalysis)

%%
% Create a graphical representation of the results:
uq_display(myBLSAnalysis)

%% 5.2 Bayesian Line Sampling with true variance
% True variance estimation and the UQLab Kriging standard options
% are now used to perform the Bayesian line sampling analysis.
%
% Select BLS as the reliability analysis method:
BLSOpts2.Type = 'Reliability';
BLSOpts2.Method = 'BLS';

%%
% Specify the maximum sample size, the size of the batch,
% and the target coefficient of variation for the MC estimation of the
% moments:
BLSOpts2.Simulation.MaxSampleSize = 1e4;
BLSOpts2.Simulation.BatchSize = 1e4;
BLSOpts2.Simulation.TargetCoV = 0.05;

%%
% Specify the learning function:
BLSOpts2.BLS.LearningFunction = 'true variance';

%%
% Set stopping CoV of the Bayesian active learning:
BLSOpts2.BLS.ConvCoV = 0.05;

%%
% Enable verbose display:
BLSOpts2.Display = 5;

%%
% Run the BLS analysis
myBLSAnalysis2 = uq_createAnalysis(BLSOpts2);

%%
% Print out a report of the results:
uq_print(myBLSAnalysis2)

%%
% Create a graphical representation of the results:
uq_display(myBLSAnalysis2)
