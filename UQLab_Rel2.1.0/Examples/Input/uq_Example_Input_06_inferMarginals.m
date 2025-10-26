%% INPUT MODULE: INFERENCE OF MARGINALS
%
% This example showcases how to infer the marginal distributions from a
% given multivariate data.

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
% The true probabilistic input model consists of two independent random
% variables:
%
% * $X_1 \sim \mathcal{N}(0, 1)$, truncated in $[1,+\inf]$
% * $X_2 \sim \textrm{Beta}(6, 4)$

%%
% Specify the marginals of these random variables:
InputTrueOpts.Marginals(1).Type = 'Gaussian';
InputTrueOpts.Marginals(1).Parameters = [0,1];
InputTrueOpts.Marginals(1).Bounds = [1,inf];

InputTrueOpts.Marginals(2).Type = 'Beta';
InputTrueOpts.Marginals(2).Parameters = [6,4];

%%
% Create an INPUT object based on the specified marginals:
myInputTrue = uq_createInput(InputTrueOpts);

%%
% Display a visualization of the INPUT object:
uq_display(myInputTrue)

%%
% Generate a sample set of size $1'000$ from the input model:
X = uq_getSample(myInputTrue,1000);

%% 3 - INFERENCE OF MARGINALS
%
% The examples below infer a joint distribution on |X| using different 
% inference options for the marginals.
% The copula, instead, is assumed known (independence copula)
InputOpts.Copula.Type = 'Independent';

%% 3.1 Full inference
%
% The marginals are inferred among all supported parametric distributions.

%%
% Assign the data set to the input options:
InputOpts.Inference.Data = X;

%%
% Create an INPUT object to infer the marginals:
InputHat1 = uq_createInput(InputOpts);

%%
% Plot the inferred input model:
uq_display(InputHat1)

%%
% Print out a report on the inferred input model:
uq_print(InputHat1)

%% 3.2 Full inference with Kolmogorov-Smirnov selection criterion
%
% The default selection criterion for the marginal distribution family is
% The Akaike information criterion (AIC). 
%
% The Kolmogorov-Smirnov criterion, meanwhile, tends to be a better choice
% for data generated from bounded marginals (such as $X_1$ in this 
% example).

%%
% Select the Kolmogorov-Smirnov (KS) selection criterion for the first
% input marginal:
InputOpts.Marginals(1).Inference.Criterion = 'KS';

%%
% Create an INPUT object to infer the marginals:
InputHat2 = uq_createInput(InputOpts);

%%
% Print out a report on the inferred input model:
uq_print(InputHat2)

%%
% Instead of specifying inference options for each marginals
% separately, it is also possible to assign collective values:
InputOpts.Inference.Criterion = 'KS';

%%
% Create an INPUT object and print out a report on the inferred input
% model:
InputHat2b = uq_createInput(InputOpts);

uq_print(InputHat2b)

%% 3.3 Full inference with truncated marginal
%
% The above inference options produce a non-truncated marginal 
% distribution. 
%
% When the data are known to be of bounded ranges and these ranges are
% known, they can be specified as an inference option:
InputOpts.Marginals(1).Bounds = [1 inf];
InputHat3 = uq_createInput(InputOpts);

%%
% Print out a report on the inferred input model:
uq_print(InputHat3)

%% 3.4 Constrained set of marginal families
%
% By default, inference of marginals is carried out among all supported
% marginals (if sensible: marginals with positive support, for instance, 
% are discarded if the inference data contain negative values).
%
% It is possible to manually set the list of parametric families to be 
% considered for inference:
InputOpts.Marginals(1).Type = {'Gaussian', 'Exponential', 'Weibull'}; 
InputHat4 = uq_createInput(InputOpts);

%%
% Print out a report on the inferred input model:
uq_print(InputHat4)

%% 3.5 Parameter fitting of a fixed marginal family
%
% If a marginal type or family is fixed,
% the inference reduces to parameter fitting:
InputOpts.Marginals(1).Type = 'Gaussian';
InputHat5 = uq_createInput(InputOpts);

%%
% Print out a report on the inferred input model:
uq_print(InputHat5);

%% 3.6 Inference of selected marginals
%
% Inference and or fitting can be limited to just some of the marginals, 
% while others can be fully specified.
%
% Below, the marginal distribution of $X_1$ is fully specified
% while that of of $X_2$ is inferred:
InputOpts.Marginals(1).Type = 'Gaussian';
InputOpts.Marginals(1).Parameters = [0 1];
InputOpts.Marginals(1).Bounds = [1 inf];

InputHat6 = uq_createInput(InputOpts);

%%
% Print out a report on the resulting input model:
uq_print(InputHat6);

%% 3.7 Inference by kernel smoothing
%
% Some data may not be suitably represented by any known parametric
% marginal distribution.
% If this is the case, a non-parametric fitting may produce better results.
%
% In the example below, the kernel smoothing (ks) is used for the second 
% marginal and the marginals are inferred.
InputOpts.Marginals(2).Type = 'ks';
InputHat7 = uq_createInput(InputOpts);

%%
% Print out a report on the inferred input model:
uq_print(InputHat7)

%% 3.8 Specification of inference options for each marginal
%
% As hinted above, all inference options for marginal distributions can 
% be specified for each marginal separately, ensuring full flexibility.
% 
% In the example below, the marginal of $X_1$ is inferred among all
% supported parametric distributions, using the Bayesian inference
% criterion (BIC), based on the first $500$ data points. 
%
% The marginal of $X_2$ is inferred as a Beta distribution,
% using the default inference criterion (AIC),
% based on all ($1000$) data points.
clear InputOpts
InputOpts.Marginals(1).Type = 'auto';
InputOpts.Marginals(1).Inference.Criterion = 'BIC';
InputOpts.Marginals(1).Inference.Data = X(1:500,1);
InputOpts.Marginals(2).Type = 'Beta';
InputOpts.Marginals(2).Inference.Data = X(:,2);

%%
% Create an INPUT object to infer the marginals:
InputHat8 = uq_createInput(InputOpts);

%%
% Print out a report on the inferred input model:
uq_print(InputHat8);

%% 3.9 Fitting parameters of a custom distribution
%
% While UQLab comes with a wide range of supported parametric marginal
% distributions, they are still a mere subset of all the known marginal
% models.
%
% However, UQLab also supports user-defined marginals.
% The user needs to define a function called |uq_<marginal name>_pdf| and 
% place the file in a folder available in the MATLAB path.
%
% For instance, the following code infers the first marginal as a marginal
% of type 'TestCustomDistribution' (which is actually a simple Gaussian
% distribution). The parameter bounds and an initial guess for inference
% are also needed.
% The parameter bounds are given below as fixed values,
% while the initial guesses are given as function of the data.
clear InputOpts
myCustom = 'TestCustomDistribution';
InputOpts.Inference.Data = X;
InputOpts.Marginals(1).Type = myCustom;
InputOpts.Marginals(1).Bounds = [1 Inf];
InputOpts.Marginals(2).Type = 'Beta';
InputOpts.Inference.ParamBounds.(myCustom) = [-Inf Inf; 0 Inf];
InputOpts.Inference.ParamGuess.(myCustom) = {@mean; @std};

InputHat9 = uq_createInput(InputOpts);

%%
% Print out a report on the inferred input model:
uq_print(InputHat9)
