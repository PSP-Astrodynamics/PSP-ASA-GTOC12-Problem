%% RELIABILITY: ACTIVE LEARNING ON THE HAT FUNCTION
%
% This example showcases the application of active learning reliability in
% UQLab, using the hat function and the default settings of the module.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace,
% set the random number generator for reproducible results
% and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL
%
% The two-dimensional hat function is defined as follows:
%
% $$g(x_1, x_2) = 20 - (x_1 - x_2)^2 - 8 (x_1 + x_2 - 4)^3$$
%
% Create a limit state function model based on the hat function
% using a string, written below in a vectorized operation:
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
% Specify the marginals of the two input random variables:
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
% The reliability analysis is performed with an active learning scheme 
% created by combining the default methods in each component of the
% framework:
%
% * Surrogate model: PC-Kriging
%
% * Reliability algorithm: Subset simulation
%
% * Learning function: Deviation number (U)
%
% * Convergence criterion: Stop Beta Bounds

%%
% Select the Reliability module and the active learning method:
ALROptions.Type = 'Reliability';
ALROptions.Method = 'ALR';

%%
% Run the active learning reliability analysis:
myALRAnalysis = uq_createAnalysis(ALROptions);

%%
% Print out a report of the results:
uq_print(myALRAnalysis)

%% 
% Visualize the results of the analysis:
uq_display(myALRAnalysis)