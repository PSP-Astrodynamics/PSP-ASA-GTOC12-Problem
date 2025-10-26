%% INPUT MODULE: INFERENCE OF MARGINALS AND COPULA
%
% This example showcases how to infer both the marginal distributions and 
% the copula from a given multivariate data.
%
% Since |uq_Example_Input_06_inferMarginals| have thoroughly showcased
% many inference options for the marginals,
% this example emphasizes on the inference options for the copula (although 
% both are inferred).

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - DATA GENERATION
%
% A hypothetical data set used for the inference is first generated using a
% reference (true) probabilistic input model.
% The input models inferred from this data set can later on be compared
% with the true one.

%%
% The true probabilistic input model consists of three random variables:
%
% * $X_1 \sim \mathcal{N}(0, 1)$
% * $X_2 \sim \textrm{Exp}(1)$
% * $X_3 \sim \mathcal{U}([0,1])$

%%
% Specify the marginals of these random variables:
iOptsTrue.Marginals(1).Type = 'Gaussian';
iOptsTrue.Marginals(1).Parameters = [-1,1];

iOptsTrue.Marginals(2).Type = 'Exponential';
iOptsTrue.Marginals(2).Parameters = 1;

iOptsTrue.Marginals(3).Type = 'Uniform';
iOptsTrue.Marginals(3).Parameters = [-1 3];

%%
% The three random variables are coupled by a canonical vine (C-vine)
% copula with the specifications as follows:
iOptsTrue.Copula.Type = 'CVine';   
iOptsTrue.Copula.Structure = [3 1 2]; 

% fix the pair copula families and rotations
iOptsTrue.Copula.Families = {'Gaussian', 'Gumbel', 't'};
iOptsTrue.Copula.Rotations = [0 90 0];
iOptsTrue.Copula.Parameters = {.4, 2, [-.2, 2]};

%%
% Create an INPUT object based on the specified marginals and copulas:
iOptsTrue.Name = 'True Input';
myInputTrue = uq_createInput(iOptsTrue);

%%
% Visualize the input model:
uq_print(myInputTrue)

%%
% Sample from the input model: 
X = uq_getSample(myInputTrue,200);

%%
% The pseudo-observations corresponding to the first sample can also be
% calculated. These are the cumulative densities of each observation
% according to its marginal distribution.
% When known, they can be used for copula inference instead of the original
% observations.
U = uq_all_cdf(X,myInputTrue.Marginals);

%% 3 - INFERENCE OF MARGINALS AND COPULA

%% 3.1 Marginals and copula inference
%
% In this example, a fully data driven inference is performed:
%
% * no information is known except the given data
% * both the marginals and the copula are inferred among the supported
%   types
% * before copula inference, a test of statistical independence is 
%   performed to split the random variables into independent subsets, 
%   if any
iOpts.Inference.Data = X;
iOpts.Name = 'InputHat 1';
InputHat1 = uq_createInput(iOpts);

%%
% Print out a report on the inferred input model:
uq_print(InputHat1)

%% 3.2 Different selection criteria for marginals and copula inference
%
% In the example below, the default inference criterion for copula (AIC) 
% is changed to the Bayesian inference criterion (BIC).
% This criterion has a stronger penalization for copula models 
% having more parameters.
iOpts.Copula.Inference.Criterion = 'BIC'; 
iOpts.Name = 'InputHat 2';
InputHat2 = uq_createInput(iOpts);

%%
% Print out a report on the inferred input model:
uq_print(InputHat2);

%% 3.3 Copula inference with fixed copula type
%
% A copula type can be fixed prior to inference and therefore only
% parameter fitting takes place.
%
% Below, the copula is fixed to be a Gaussian copula:
iOpts.Copula.Type = 'Gaussian';
iOpts.Name = 'InputHat 3';
InputHat3 = uq_createInput(iOpts);

%%
% Print out a report on the inferred input model:
uq_print(InputHat3);

%% 3.4 Marginals inference with fully specified copula
%
% The copula type as well as its parameters can be fully specified at the
% outset. This specification limits the inference only to the marginals.

%%
% In the example below, the parameter of a Gaussian copula is specified:
iOpts.Copula.Parameters = [1 -.4 .3; -.4 1 -.6; .3 -.6 1];
iOpts.Name = 'InputHat 4';
InputHat4 = uq_createInput(iOpts);

%%
% Print out a report on the inferred input model:
uq_print(InputHat4);

%% 3.5 Copula inference with fixed marginals
%
% Contrary to the previous case, the marginals can be fully specified at
% the outset and thus limits the inference only to the copula:
clear iOpts
iOpts.Marginals(1).Type = 'Gaussian';
iOpts.Marginals(1).Parameters = [-1,1];
iOpts.Marginals(2).Type = 'Exponential';
iOpts.Marginals(2).Parameters = [1];
iOpts.Marginals(3).Type = 'Uniform';
iOpts.Marginals(3).Parameters = [-1 3];
iOpts.Inference.Data = X;

iOpts.Name = 'InputHat 5';
InputHat5 = uq_createInput(iOpts);

%%
% Print out a report on the inferred input model:
uq_print(InputHat5)

%% 3.6 Copula inference using different data
%
% Sometimes, the same amount of observation is not available to infer 
% the marginals and the copula.
% For instance, joint observations from the full random vector 
% may be fewer than observations from the individual variables.
%
% In the example below, the copula is inferred on a smaller data set,
% taking every second observation.
iOpts.Copula.Inference.Data = X(1:2:end,:);
iOpts.Name = 'InputHat 6';
InputHat6 = uq_createInput(iOpts);

%%
% Print out a report on the inferred input model:
uq_print(InputHat6)

%% 3.7 Copula inference on pseudo-observations in the unit hypercube
%
% Finally, in the example below, the copula is inferred based on the 
% pseudo-observations in the unit hypercube:
clear iOpts
iOpts.Marginals(1).Type = 'Gaussian';
iOpts.Marginals(1).Parameters = [-1,1];
iOpts.Marginals(2).Type = 'Exponential';
iOpts.Marginals(2).Parameters = 1;
iOpts.Marginals(3).Type = 'Uniform';
iOpts.Marginals(3).Parameters = [-1 3];
iOpts.Copula.Inference.DataU = U;

iOpts.Name = 'InputHat 7';
InputHat7 = uq_createInput(iOpts);

%%
% Print out a report on the inferred input model:
uq_print(InputHat7)
