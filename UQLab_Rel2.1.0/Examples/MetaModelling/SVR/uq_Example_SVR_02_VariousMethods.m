%% SVR METAMODELING: VARIOUS METHODS
%
% This example showcases how to perform Support Vector Machine for 
% Regression (SVR) metamodeling for a simple one-dimensional function,
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
% $$Y(x) = x \sin(x), \; x \in [0, 15]$$
%
% The model can be specified directly using a string,
% written below in a vectorized operation:
ModelOpts.mString = 'X.*sin(X)';
ModelOpts.isVectorized = true;

%%
% Create a MODEL based on the specified options:
myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of a uniform random variable:
%
% $$X \sim \mathcal{U}(0, 15)$$

%%
% Specify the probabilistic model of the input variable:
InputOpts.Marginals.Type = 'Uniform';
InputOpts.Marginals.Parameters = [0 15];

%%
% Create an INPUT object based on the specified marginal:
myInput = uq_createInput(InputOpts);

%% 4 - EXPERIMENTAL DESIGN AND MODEL RESPONSES
%
% An experimental design is generated and the corresponding 
% model responses are calculated. 
% They are later used for creating several different SVR metamodels.
%
% Generate $10$ sample points from the input model
% using the latin hypercube sampling (LHS):
X = uq_getSample(10,'LHS');

%%
% Evaluate the corresponding model responses:
Y = uq_evalModel(X);

%% 5 - SVR METAMODELS
%
% Select the metamodeling tool and the SVR module:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'SVR';

%% 
% Use the experimental design and corresponding model responses 
% generated earlier:
MetaOpts.ExpDesign.X = X;
MetaOpts.ExpDesign.Y = Y;

%%
% Select the 'Matern 5/2' kernel family:
MetaOpts.Kernel.Family = 'Matern-5_2';

%%
% The previous set of options are fixed and will be used for all 
% the SVR metamodels created below.
% The optimization and hyperparameter estimation methods vary
% for each SVR metamodel.

%%
% * Create an SVR model using the Span leave-one-out (LOO) error estimator
%   and BFGS optimization method:
disp(['> Estimation Method: LOO span estimate, ',...
    'Optimization method: BFGS'])
MetaOpts.EstimMethod = 'SpanLOO';
MetaOpts.Optim.Method = 'BFGS';
mySVR_Span_BFGS = uq_createModel(MetaOpts);

%%
% * Create an SVR model using the Span LOO error estimator
%   and HCMAES optimization method:
disp(['> Estimation Method: LOO span estimate, ',...
    'Optimization method: HCMAES'])
MetaOpts.Optim.Method = 'HCMAES';
mySVR_Span_HCMAES = uq_createModel(MetaOpts);

%%
% * Create an SVR model using the Smooth LOO error estimator
%   and BFGS optimization method:
disp(['> Estimation Method: Smoothed LOO span estimate, ',...
    'Optimization method: BFGS'])
MetaOpts.EstimMethod = 'SmoothLOO';
MetaOpts.Optim.Method = 'BFGS';
mySVR_Smooth_BFGS = uq_createModel(MetaOpts);

%%
% * Create an SVR model using the Smooth LOO error estimator 
%   and HCE optimization method:
disp(['> Estimation Method: Smoothed LOO span estimate, ',...
    'Optimization method: HCE'])
MetaOpts.Optim.Method = 'HCE';
mySVR_Smooth_HCE = uq_createModel(MetaOpts);

%%
% * Create an SVR model using the Cross Validation error estimator 
%   and BFGS optimization method:
disp(['> Estimation Method: Cross-Validation, ',...
    'Optimization method: BFGS'])
MetaOpts.EstimMethod = 'CV';
MetaOpts.Optim.Method = 'BFGS';
MetaOpts.Optim.maxIter = 30;
mySVR_CV_BFGS = uq_createModel(MetaOpts);

%% 
% * Create a SVR model using the Cross-Validation (CV) error estimator
%   and HGA optimization method:
disp(['> Estimation Method: Cross-Validation, ',...
    'Optimization method: HGA'])
MetaOpts.Optim.Method = 'HGA';
mySVR_CV_HGA = uq_createModel(MetaOpts) ;

%% 6 - COMPARISON OF THE METAMODELS
%
% Create a validation set:
Nval = 1e3;
Xval = linspace(0, 15, Nval)';

%%
% Evaluate the full model responses at the validation set:
Yval = uq_evalModel(myModel,Xval);

%%
% Evaluate the corresponding responses for each of the generated SVR
% metamodel.
Y_Span_BFGS  = uq_evalModel(mySVR_Span_BFGS,Xval);
Y_Span_HCMAES = uq_evalModel(mySVR_Span_HCMAES,Xval);
Y_Smooth_BFGS = uq_evalModel(mySVR_Smooth_BFGS,Xval);
Y_Smooth_HCE = uq_evalModel(mySVR_Smooth_HCE,Xval);
Y_CV_BFGS = uq_evalModel(mySVR_CV_BFGS,Xval);
Y_CV_HGA = uq_evalModel(mySVR_CV_HGA,Xval);

%%
% Comparative plots of the SVR predictors are created.
% They are divided into three groups based on the hyperparameter
% estimation methods.
%
% * LOO Span estimate:
uq_figure

uq_plot(...
    Xval, Yval, 'k',...
    Xval, Y_Span_BFGS,...
    Xval, Y_Span_HCMAES, '--',...
    X, Y, 'ko')

axis([0 15 -15 25])
xlabel('$\mathrm{X}$')
ylabel('$\mathrm{\widehat{Y}(x)}$')
title('LOO span estimate')
uq_legend(...
    {'Original model',...
        'SVR, optim. method: BFGS',...
        'SVR, optim. method: HCMAES',...
        'Observations'},...
    'Location', 'north')

%%
% * Smooth LOO span estimate:
uq_figure

uq_plot(...
    Xval, Yval, 'k',...
    Xval, Y_Smooth_BFGS,...
    Xval, Y_Smooth_HCE, '--',...
    X, Y, 'ko')

axis([0 15 -15 25])
xlabel('$\mathrm{X}$')
ylabel('$\mathrm{\widehat{Y}(x)}$')
title('Smoothed LOO span estimate')
uq_legend(...
    {'Original model',...
        'SVR, optim. method: BFGS',...
        'SVR, optim. method: HCE',...
        'Observations'},...
    'Location', 'north')

%%
% * Cross-validation (CV)-based estimation:
uq_figure

uq_plot(...
    Xval, Yval, 'k',...
    Xval, Y_CV_BFGS,...
    Xval, Y_CV_HGA, '--',...
    X, Y, 'ko')

axis([0 15 -15 25])
xlabel('$\mathrm{X}$')
ylabel('$\mathrm{\widehat{Y}(x)}$')
title('(LOO) Cross-Validation')
uq_legend(...
    {'Original model',...
        'SVR, optim. method: BFGS',...
        'SVR, optim. method: HGA',...
        'Observations'},...
    'Location', 'north')
