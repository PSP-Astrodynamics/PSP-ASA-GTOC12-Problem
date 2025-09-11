%% INPUT MODULE: MARGINALS AND GAUSSIAN COPULA
%
% This example showcases how to define a probabilistic input model with or
% without a copula dependency.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace
% and initialize the UQLab framework:
clearvars
uqlab

%% 2 - PROBABILISTIC INPUT MODEL (WITHOUT DEPENDENCY)
%
% The probabilistic input model consists of two variables:
%%
% $X_1 \sim \mathcal{N}(0, 1)$
InputOpts.Marginals(1).Type = 'Gaussian';
InputOpts.Marginals(1).Parameters = [0 1];
%%
% $X_2 \sim \mathcal{B}(1, 3)$
InputOpts.Marginals(2).Type = 'Beta';
InputOpts.Marginals(2).Parameters = [1 3];
%%
% By default, the variables are considered independent.

%%
% Create an INPUT object based on the specified marginals:
myInputIndependent = uq_createInput(InputOpts);

%%
% Print a report of the INPUT object:
uq_print(myInputIndependent)

%% 2 - PROBABILISTIC INPUT MODEL (WITH DEPENDENCY: GAUSSIAN COPULA)
%
% The marginal distributions of the probabilistic input model are already
% defined inside the structure |InputOpts|.
% A dependency following a Gaussian copula is added as follows:
InputOpts.Copula.Type = 'Gaussian';
InputOpts.Copula.RankCorr = [1 0.8; 0.8 1];  % the Spearman corr. matrix

%%
% Create an INPUT object based on the specified marginals and copula:
myInputDependent = uq_createInput(InputOpts);

%%
% Print a report of the INPUT object:
uq_print(myInputDependent)

%% 3 - COMPARISON OF THE INPUT MODELS
%
% Each of the generated INPUT objects can be quickly visualized using
% the function |uq_display|.
%
% For the independent INPUT object:
uq_display(myInputIndependent)

%%
% For the dependent INPUT object:
uq_display(myInputDependent)
