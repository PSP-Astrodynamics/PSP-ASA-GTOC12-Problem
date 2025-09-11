%% INPUT MODULE: SAMPLING STRATEGIES
%
% This example showcases how to define a probabilistic input model
% and then use it to draw samples using various sampling strategies. 

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(1,'twister')
uqlab

%% 2 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of two uniform random variables:
%
% $$X_i \sim \mathcal{U}(0, 1) \qquad i = 1,2$$

%%
% Specify the marginals:
InputOpts.Marginals(1).Type = 'Uniform';
InputOpts.Marginals(1).Parameters = [0 1];
InputOpts.Marginals(2).Type = 'Uniform';
InputOpts.Marginals(2).Parameters = [0 1];

%%
% Create an INPUT object based on the specified marginals:
myInput = uq_createInput(InputOpts);

%%
% Print a report on the created INPUT object: 
uq_print(myInput)

%% 3 - DRAWING SAMPLES
%
% Different samples from the INPUT object are drawn
% using various sampling strategies.

%% 3.1 Monte Carlo sampling

X_MC = uq_getSample(80,'MC');

uq_figure
uq_plot(X_MC(:,1), X_MC(:,2), '.', 'MarkerSize', 10)
xlabel('$\mathrm{X_1}$')
ylabel('$\mathrm{X_2}$')

%% 3.2 Latin hypercube sampling

X_LHS = uq_getSample(80, 'LHS');

uq_figure
uq_plot(X_LHS(:,1), X_LHS(:,2), '.', 'MarkerSize', 10)
xlabel('$\mathrm{X_1}$')
ylabel('$\mathrm{X_2}$')

%% 3.3 Sobol' sequence sampling

X_Sobol = uq_getSample(80,'Sobol');

uq_figure
uq_plot(X_Sobol(:,1), X_Sobol(:,2), '.', 'MarkerSize', 10)
xlabel('$\mathrm{X_1}$')
ylabel('$\mathrm{X_2}$')

%% 3.4 Halton sequence sampling

X_Halton = uq_getSample(80,'Halton');

uq_figure
uq_plot(X_Halton(:,1), X_Halton(:,2), '.', 'MarkerSize', 10)
xlabel('$\mathrm{X_1}$')
ylabel('$\mathrm{X_2}$')

%% 4 - COMPARISON OF SAMPLING STRATEGIES
%
% Finally, plots of the different sampling strategies are shown
% for comparison:
uq_figure

subplot(2, 2, 1)
uq_plot(X_MC(:,1), X_MC(:,2), '.', 'MarkerSize', 10)
title('MCS')
ylabel('$\mathrm{X_2}$')

subplot(2, 2, 2)
uq_plot(X_LHS(:,1), X_LHS(:,2), '.', 'MarkerSize', 10)
title('LHS')

subplot(2, 2, 3)
uq_plot(X_Sobol(:,1), X_Sobol(:,2), '.', 'MarkerSize', 10)
title('Sobol''')
xlabel('$\mathrm{X_1}$')
ylabel('$\mathrm{X_2}$')

subplot(2, 2, 4)
uq_plot(X_Halton(:,1), X_Halton(:,2), '.', 'MarkerSize', 10)
title('Halton')
xlabel('$\mathrm{X_1}$')
