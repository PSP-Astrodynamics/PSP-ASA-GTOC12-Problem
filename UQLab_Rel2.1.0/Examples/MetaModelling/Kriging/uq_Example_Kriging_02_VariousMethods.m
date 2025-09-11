%% KRIGING METAMODELING: VARIOUS METHODS
%
% This example showcases how to perform Kriging metamodeling
% for a simple one-dimensional function,
% using various hyperparameter estimation and optimization methods.

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
% Specify this model in UQLab using a string with vectorized operation:
ModelOpts.Name = 'XsinX';
ModelOpts.mString = 'X.*sin(X)';
ModelOpts.isVectorized = true;

myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of one uniform random variable:
% 
% $X \sim \mathcal{U}(0, 15)$
%
% Specify the marginal and create a UQLab INPUT object:
InputOpts.Marginals.Type = 'Uniform';
InputOpts.Marginals.Parameters = [0 15];

myInput = uq_createInput(InputOpts);

%% 4 - EXPERIMENTAL DESIGN AND MODEL RESPONSES
%
% Generate $10$ sample points of $X$ using the Sobol' sequence sampling:
X = uq_getSample(10,'Sobol');

%%
% Evaluate the corresponding model responses:
Y = uq_evalModel(X);

%% 5 - KRIGING METAMODELS
%
% Select the metamodeling tool and the Kriging module:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'Kriging';

%% 
% Assign the experimental design and the corresponding model responses:
MetaOpts.ExpDesign.X = X;
MetaOpts.ExpDesign.Y = Y;

%%
% Perform ordinary Kriging
% (i.e., Kriging with a constant but unknown trend):
MetaOpts.Trend.Type = 'ordinary';

%%
% Set the correlation family to Matérn 5/2:
MetaOpts.Corr.Family = 'matern-5_2';

%%
% The previous options are fixed, i.e., all the Kriging
% metamodels that will be created will use them. 
% The selected optimization and hyperparameter estimation method, however, 
% varies for each Kriging metamodel that is created next:
disp(['> Estimation Method: Maximum-Likelihood, ',...
    'Optimization method: BFGS'])
MetaOpts.EstimMethod = 'ML';
MetaOpts.Optim.Method = 'BFGS';
myKriging_ML_BFGS = uq_createModel(MetaOpts) ;
fprintf('\n\n')

disp(['> Estimation Method: Maximum-Likelihood, ',...
    'Optimization method: HGA'])
MetaOpts.Optim.Method = 'HGA';
myKriging_ML_HGA = uq_createModel(MetaOpts) ;
fprintf('\n\n')

disp(['> Estimation Method: Cross-Validation, ',...
    'Optimization method: BFGS'])
MetaOpts.EstimMethod = 'CV';
MetaOpts.Optim.Method = 'BFGS';
MetaOpts.Optim.maxIter = 30;
myKriging_CV_BFGS = uq_createModel(MetaOpts) ;
fprintf('\n\n')

disp(['> Estimation Method: Cross-Validation, ',...
    'Optimization method: HGA'])
MetaOpts.Optim.Method = 'HGA';
myKriging_CV_HGA = uq_createModel(MetaOpts) ;

%% 6 - COMPARISON OF THE METAMODELS
%
% Create a validation set of size $10^3$ over a regular grid:
Xval = uq_getSample(10^3,'grid');

%%
% Evaluate the true model response at the validation sample points:
Yval = uq_evalModel(myModel,Xval);

%%
% Evaluate the Kriging surrogate predictions on the validation set.
% In each case, both the mean and the variance of the Kriging predictor
% are calculated:
[Ymu_ML_BFGS,Yvar_ML_BFGS]  = uq_evalModel(myKriging_ML_BFGS,Xval);
[Ymu_ML_HGA,Yvar_ML_HGA] = uq_evalModel(myKriging_ML_HGA,Xval);
[Ymu_CV_BFGS,Yvar_CV_BFGS] = uq_evalModel(myKriging_CV_BFGS,Xval);
[Ymu_CV_HGA,Yvar_CV_HGA] = uq_evalModel(myKriging_CV_HGA,Xval);

%%
% Lastly, comparison plots for the mean and the variance of the Kriging
% predictors are generated.
% They are divided into two groups based on the hyperparameter estimation 
% method.

%%
% * Maximum likelihood estimation (mean):
uq_figure

uq_plot(...
    Xval, Yval, 'k',...
    Xval, Ymu_ML_BFGS,...
    Xval, Ymu_ML_HGA, '--',...
    X, Y, 'ko')

axis([0 15 -15 25])

uq_legend({'True model', 'Kriging, optim. method: BFGS',...
    'Kriging, optim. method: HGA', 'Observations'},...
    'Location','north')

xlabel('$\mathrm{X}$')
ylabel('$\mathrm{\mu_{\widehat{Y}}}$')
title('Maximum likelihood')

%%
% * Maximum likelihood estimation (variance):
uq_figure

uq_plot(...
    X, zeros(size(X)), 'k',...
    Xval, Yvar_ML_BFGS,...
    Xval, Yvar_ML_HGA, '--',...
    X, zeros(size(X)), 'ko')

axis([0 15 0 30])

uq_legend({'True model', 'Kriging, optim. method: BFGS',...
    'Kriging, optim. method: HGA', 'Observations'},...
    'Location', 'north')

xlabel('$\mathrm{X}$')
ylabel('$\mathrm{\sigma^2_{\widehat{Y}}}$')
title('Maximum likelihood')

%%
% * Cross-validation-based estimation (mean):
uq_figure

uq_plot(...
    Xval, Yval, 'k',...
    Xval, Ymu_CV_BFGS,...
    Xval, Ymu_CV_HGA, '--',...
    X, Y, 'ko')

axis([0 15 -15 25])

uq_legend({'True model', 'Kriging, optim. method: BFGS',...
    'Kriging, optim. method: HGA', 'Observations'},...
    'Location', 'north')

xlabel('$\mathrm{X}$')
ylabel('$\mathrm{\mu_{\widehat{Y}}}$')
title('(LOO/N-fold) Cross-validation')

%%
% * Cross-validation-based estimation (variance):
uq_figure

uq_plot(...
    X, zeros(size(X)), 'k',...
    Xval, Yvar_CV_BFGS,...
    Xval, Yvar_CV_HGA, '--',...
    X, zeros(size(X)), 'ko')

axis([0 15 0 30])

uq_legend({'True model', 'Kriging, optim. method: BFGS',...
    'Kriging, optim. method: HGA', 'Observations'},...
    'Location', 'north')

xlabel('$\mathrm{X}$')
ylabel('$\mathrm{\sigma^2_{\widehat{Y}}}$')
title('(LOO) Cross-Validation')
