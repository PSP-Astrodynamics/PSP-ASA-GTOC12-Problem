%% KRIGING METAMODELING: NOISY MODEL RESPONSE (GAUSSIAN PROCESS REGRESSION)
%
% This example illustrates how to perform Kriging regression
% on noisy data.
% The example is based on a simple one-dimensional function similar to the
% one in |uq_Example_Kriging_01_1D|, now with additive Gaussian noise
% added to the model response.
% Three cases of noise variance are considered:
% unknown homogeneous (homoscedastic), known homoscedastic,
% and known heterogeneous (heteroscedastic).

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(0,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL
%
% The computational model is a simple analytical function defined by:
%
% $$y(x) = x \sin(x), \; x \in [-3\pi, 3\pi]$$
% 
% Specify this model using a string and create a UQLab MODEL object:
ModelOpts.mString = 'X.*sin(X)';
ModelOpts.isVectorized = true;

myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of a single uniform random
% variable: 
% 
% $X \sim \mathcal{U}(-3\pi, 3\pi)$
%
% Specify its marginal distribution and create a UQLab INPUT object:
InputOpts.Marginals.Type = 'Uniform';
InputOpts.Marginals.Parameters = [-3*pi 3*pi];

myInput = uq_createInput(InputOpts);

%% 4 - KRIGING REGRESSION MODELS
%
% Three cases of noise variance are considered below:
% unknown homogeneous (homoscedastic), known homoscedastic,
% and known heterogeneous (heteroscedastic).

%% 4.1 Unknown homogeneous (homoscedastic) noise
%
% In the first case, a Kriging model is built on a noisy data set, while
% also estimating the unknown homogeneous (homoscedastic) noise variance.

%%
% Create an experimental design:
Ntrain = 50;
X = uq_getSample(myInput,Ntrain);

%%
% Evaluate the corresponding model responses:
Y = uq_evalModel(myModel,X);

%%
% Add random Gaussian noise with $\sigma_\epsilon = 0.2\sigma_Y$
% to the model response:
Y = Y + 0.2*std(Y)*randn(size(Y,1),1);

%%
% Select the metamodeling tool and the Kriging module:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'Kriging';

%% 
% Use the experimental design and corresponding model responses 
% generated earlier:
MetaOpts.ExpDesign.X = X;
MetaOpts.ExpDesign.Y = Y;

%% 
% Estimate the homogeneous noise variance:
MetaOpts.Regression.SigmaNSQ = 'auto';

%%
% Create the Kriging metamodel:
myKrigingRegression1 = uq_createModel(MetaOpts);

%% 
% Print out a report on the resulting Kriging object:
uq_print(myKrigingRegression1)

%%
% Visualize the result:
uq_display(myKrigingRegression1)

ylim([-10 15])  % set the plot limits for comparison with the other models

%% 4.2 Known homogeneous (homoscedastic) noise
%
% The second case illustrates how to build a Kriging model for a noisy data
% assuming the homogeneous noise variance is known a priori.

%%
% Create an experimental design:
Ntrain = 50;
X = uq_getSample(myInput,Ntrain);

%%
% Evaluate the corresponding model responses:
Y = uq_evalModel(myModel,X);

%%
% Add a random noise to the model responses:
noiseVar = 1.0;
Y = Y + sqrt(noiseVar)*randn(size(Y,1),1);

%%
% Select the metamodeling tool and the Kriging module:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'Kriging';

%% 
% Use the experimental design and corresponding model responses 
% generated earlier:
MetaOpts.ExpDesign.X = X;
MetaOpts.ExpDesign.Y = Y;

%% 
% Impose a known homoscedastic noise variance:
MetaOpts.Regression.SigmaNSQ = noiseVar;

%%
% Create the Kriging metamodel:
myKrigingRegression2 = uq_createModel(MetaOpts);

%% 
% Print out a report on the resulting Kriging object:
uq_print(myKrigingRegression2)

%%
% Plot a representation of the mean and the 95% confidence bounds of the
% Kriging regression model:
uq_display(myKrigingRegression2)

ylim([-10 15])  % set the plot limits for comparison with the other models

%% 4.3 Known non-homogeneous (heteroscedastic) noise
%
% In the third case, Kriging regression model is built from a data set with 
% non-homogeneous (heteroscedastic) noise variance, known at individual
% data points. The variances differ but remain independent.

%%
% Create an experimental design:
Ntrain = 50;
X = uq_getSample(myInput,Ntrain,'grid');

%%
% Evaluate the corresponding model responses:
Y = uq_evalModel(myModel,X);

%%
% Define a vector of noise variance at individual data locations:
noiseVar = (0.3*abs(Y)).^2;

%%
% Add a random noise to the model responses:
Y = Y + sqrt(noiseVar).*randn(size(Y));

%%
% Select the metamodeling tool and the Kriging module:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'Kriging';

%% 
% Use the experimental design and corresponding model responses 
% generated earlier:
MetaOpts.ExpDesign.X = X;
MetaOpts.ExpDesign.Y = Y;

%% 
% Impose the known heteroscedastic noise variance:
MetaOpts.Regression.SigmaNSQ = noiseVar;

%%
% Create the Kriging regression model:
myKrigingRegression3 = uq_createModel(MetaOpts);

%%
% Visualize the results and add an error bar to each data point:
uq_display(myKrigingRegression3)
hold on
errorbar(X, Y, 2*sqrt(noiseVar), 'kx', 'HandleVisibility', 'off')
hold off

ylim([-10 15])  % set the plot limits for comparison with the other models