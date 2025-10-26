%% KRIGING METAMODELING: ONE-DIMENSIONAL EXAMPLE
%
% This example showcases how to perform Kriging metamodeling
% on a simple one-dimensional function
% using various types of correlation families.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace,
% set the random number generator for reproducible results,
% and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL
%
% The computational model is a simple analytical function defined by:
%
% $$Y = x \sin(x), \; x \in [0, 15]$$
%
% In UQLab, the model can be specified directly as a string,
% written below in a vectorized operation:
ModelOpts.mString = 'X.*sin(X)';
ModelOpts.isVectorized = true;

myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of a single 
% uniform random variable:
%
% $$X \sim \mathcal{U}(0, 15)$$

%%
% Specify the probabilistic model of the input variable:
InputOpts.Marginals.Type = 'Uniform';
InputOpts.Marginals.Parameters = [0 15];

%%
% Then create an INPUT object:
myInput = uq_createInput(InputOpts);

%% 4 - EXPERIMENTAL DESIGN AND MODEL RESPONSES
%
% Generate an experimental design $X$ of size $8$ 
% using the latin hypercube sampling (LHS):
X = uq_getSample(8,'LHS');

%%
% Evaluate the corresponding model responses:
Y = uq_evalModel(X);

%% 5 - KRIGING METAMODELS
%
% Three different correlation functions of the underlying Gaussian process
% to create Kriging metamodels are considered.

%% 5.1 Matérn 5/2 correlation
% Select the metamodeling tool and the Kriging module:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'Kriging';

%% 
% Use the experimental design and corresponding model responses 
% generated earlier:
MetaOpts.ExpDesign.X = X;
MetaOpts.ExpDesign.Y = Y;

%%
% Create the Kriging metamodel:
myKrigingMat = uq_createModel(MetaOpts);

%%
% Note that the various options that have not been explicitly specified 
% have been automatically assigned to their default values. 
% This includes the correlation family which is set to Matérn 5/2
% by default. 

%% 
% Print out a report on the resulting Kriging object:
uq_print(myKrigingMat)

%%
% Plot a representation of the mean and the 95% confidence bounds of the
% Kriging predictor:
uq_display(myKrigingMat)

%% 5.2 Linear correlation
%
% Create another Kriging metamodel with the same configuration
% options but use a linear correlation family instead: 
MetaOpts.Corr.Family = 'linear';
myKrigingLin = uq_createModel(MetaOpts);

%% 5.3 Exponential correlation
%
% Finally, create a Kriging metamodel using the exponential correlation family:
MetaOpts.Corr.Family = 'exponential';
myKrigingExp = uq_createModel(MetaOpts);

%% 6 - METAMODELS VALIDATION
%
% Create a validation set of size $10^3$ over a regular grid:
Xval = uq_getSample(10^3,'grid');

%%
% Evaluate the true model responses for the validation set:
Yval = uq_evalModel(myModel,Xval);

%%
% Evaluate the Kriging surrogate predictions on the validation set.
% In each case, both the mean and the variance of the Kriging predictor
% are calculated:
[YMeanMat,YVarMat] = uq_evalModel(myKrigingMat,Xval);
[YMeanLin,YVarLin] = uq_evalModel(myKrigingLin,Xval);
[YMeanExp,YVarExp] = uq_evalModel(myKrigingExp,Xval);

%%
% Compare the mean prediction of each Kriging metamodel on the validation
% set (also taking into account the true model responses):
uq_figure
uq_plot(...
    Xval, Yval, 'k',...
    Xval, YMeanMat,...
    Xval, YMeanLin,...
    Xval, YMeanExp,...
    X, Y, 'ko')
% Set axes limits
xlim([0 15])
ylim([-20 30])
% Set labels
xlabel('$\mathrm{X}$')
ylabel('$\mathrm{\mu_{\widehat{Y}}(x)}$')
uq_legend(...
    {'True model', 'Kriging, R: Matern 5/2', 'Kriging, R: Linear',...
    'Kriging, R: Exponential', 'Observations'},...
    'Location', 'northwest')

%%
% Finally, compare the variance that is predicted by each Kriging
% metamodel:
uq_figure
uq_plot(...
    Xval, YVarMat,...
    Xval, YVarLin,...
    Xval, YVarExp,...
    X, zeros(size(X)), 'ko')
% Set labels
xlabel('$\mathrm{X}$')
ylabel('$\mathrm{\sigma^2_{\widehat{Y}}(x)}$')
uq_legend(...
    {'Kriging, R: Matern 5/2', 'Kriging, R: Linear',...
    'Kriging, R: Exponential', 'Observations'}, 'Location', 'north')
