%% RELIABILITY: ADVANCED ACTIVE LEARNING ON THE TWO-DIMENSIONAL HAT FUNCTION
%
% In this example, it is shown how advanced options of active learning
% reliability can be set. Three cases are illustrated, each relating to a
% specific aspect of the framework:
%
% * Enrichment and convergence criteria
%
% * Surrogate model options
%
% * Reliability algorithms options
%
%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace,
% set the random number generator for reproducible results
% and initialize the UQLab framework:
clearvars
rng(10,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL
%
% The two-dimensional hat function is defined as follows:
%
% $$g(x_1, x_2) = 20 - (x_1 - x_2)^2 - 8 (x_1 + x_2 - 4)^3$$
%
% Create a limit state function model based on the hat function
% using a string (vectorized):
ModelOpts.mString = '20 - (X(:,1)-X(:,2)).^2 - 8*(X(:,1)+X(:,2)-4).^3';
ModelOpts.isVectorized = true;
myModel = uq_createModel(ModelOpts);


%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of two independent
% and identically-distributed Gaussian random variables:
%
% $X_i \sim \mathcal{N}(0.25, 1), \quad i = 1, 2$
%
% Specify the probabilistic model for the two input random variables:
InputOpts.Marginals(1).Name = 'X1';
InputOpts.Marginals(1).Type = 'Gaussian';
InputOpts.Marginals(1).Parameters = [0.25 1];

InputOpts.Marginals(2).Name = 'X2';
InputOpts.Marginals(2).Type = 'Gaussian';
InputOpts.Marginals(2).Parameters = [0.25 1];

%%
% Create the INPUT object:
myInput = uq_createInput(InputOpts);

%% 4 - STRUCTURAL RELIABILITY
%
% Failure event is defined as $g(\mathbf{x}) \leq 0$.
% The failure probability is then defined as
% $P_f = P[g(\mathbf{x})\leq 0]$.
%
% Three reliability analyses are performed and in each instance, a specific
% aspect of the framework is finely tuned.

%%
% Select the Reliability module and the active learning method:
ALROptions.Type = 'Reliability';
ALROptions.Method = 'ALR';

%% 4.1 - Enrichment and convergence options

%%
% Specify the number of enrichment points per iteration
ALROptions.ALR.NumOfPoints = 2 ;

%%
% Specify options related to convergence
%
% Here we combine two stopping criteria i.e., the algorithm will stop only
% when the two conditions are satisfied
ALROptions.ALR.Convergence = {'StopBetaBound','StopBetaStab'} ;

%%
% Specify the convergence threshold for each of the stopping criteria
ALROptions.ALR.ConvThres =  [0.01 0.05] ;

%%
% Specify the maximum number of enrichment points
ALROptions.ALR.MaxAddedED = 20 ;

%%
% Run the active learning reliability analysis:
myALRAnalysis = uq_createAnalysis(ALROptions);

%%
% Print out a report of the results:
uq_print(myALRAnalysis)

%%
% Visualize the results of the analysis:
uq_display(myALRAnalysis)

%% 4.2 - Metamodel options

%%
% Select Kriging as surrogate model
ALROptions.ALR.Metamodel = 'Kriging' ;

%%
% Any option from the Kriging module can be
% specified here, for instance:
%
% * Correlation function options
KRGOptions.Corr.Family = 'Gaussian' ;
KRGOptions.Corr.Nugget = 1e-10 ;

%%
% * Optimization options
KRGOptions.EstimMethod = 'ML' ;
KRGOptions.Optim.Method = 'HGA' ;

%%
% After defining the options, assign them to the ALR algorithm
ALROptions.ALR.Kriging = KRGOptions ;

%%
% Run the analysis
myALRAnalysis = uq_createAnalysis(ALROptions);

%%
% Print out a report of the results:
uq_print(myALRAnalysis)

%%
% Visualize the results of the analysis:
uq_display(myALRAnalysis)

%% 4.3 - Modify the reliability algorithm and its options
%%
% The default reliability algorithm is subset simulation. Below, we will
% specify its options for the analysis
%%
% Specify the sample size in each subset
ALROptions.Simulation.BatchSize = 1e4;
%%
% Specify the maximum sample size
ALROptions.Simulation.MaxSampleSize = 1e6;
%%
% Specify the target conditional failure probability in each subset ($p_0$)
ALROptions.Subset.p0 = 0.2 ;

%%
% Run the active learning reliability analysis:
myALRAnalysis = uq_createAnalysis(ALROptions);

%%
% Print out a report of the results
%
% Notice how the coefficient of variation of the estimated failure
% probability has decreased (compred to the two previous cases) thanks to
% the specification of a more robust setting for subset simulation.
uq_print(myALRAnalysis)

%%
% Visualize the results of the analysis:
uq_display(myALRAnalysis)