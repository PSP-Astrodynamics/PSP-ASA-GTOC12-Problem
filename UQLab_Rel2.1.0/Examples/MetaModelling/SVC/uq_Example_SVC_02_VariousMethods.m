%% SVC METAMODELING: VARIOUS METHODS
%
% This example showcases how to perform Support Vector Machine for
% Classification (SVC) metamodeling for a simple two-dimensional function,
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
% The computational model is an analytical function defined as:
%
% $$Y(\mathbf{x}) = \left\{ \begin{array}{ll}
%   -1 & \quad Y_{val}(\mathbf{x}) < 0  \\
%   +1 & \quad Y_{val}(\mathbf{x}) > 0 \\
% \end{array}\right.$$
%
% $Y_{val}(\mathbf{x}) = x_2 - x_1 \sin(x_1) - 1$
%
% This model is implemented in the UQLab function |uq_cmsin|.

%%
% Create a MODEL object from the function file:
ModelOpts.mFile = 'uq_cmsin';

myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of two uniform random variables:
%
% $$X_i \in \mathcal{U}(0, 10), \; i = 1,2$$

%%
% Specify the distributions of the input variables:
Input.Marginals(1).Type = 'Uniform';
Input.Marginals(1).Parameters = [0 10];
Input.Marginals(2).Type = 'Uniform';
Input.Marginals(2).Parameters = [0 10];

%%
% Create an INPUT object:
myInput = uq_createInput(Input);

%% 4 - SVC METAMODELS
%
% Select the metamodeling tool and the SVC module:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'SVC';

%%
% Specify the sampling strategy and the number of sample points
% for the experimental design:
MetaOpts.ExpDesign.Sampling = 'LHS';
MetaOpts.ExpDesign.NSamples = 100;

%%
% Assign the previously created INPUT and MODEL objects:
MetaOpts.Input = myInput;
MetaOpts.FullModel = myModel;
%%
% If an INPUT object and a MODEL object are specified,
% an experimental design is automatically generated
% and the corresponding model responses are computed.

%%
% Select the 'Matérn 5/2' kernel family:
MetaOpts.Kernel.Family = 'matern-5_2';

%%
% Select the anisotropic kernel option:
MetaOpts.Kernel.Isotropic = false;

%%
% The previous set of options are fixed and will be used for all the SVC
% metamodels created below.
% The optimization and hyperparameter estimation methods vary
% for each SVC metamodel.

%%
% * Create an SVC model using the Span leave-one-out (LOO) error estimator
%   and the Grid Search optimization method:
disp(['> Estimation Method: LOO span estimate, ',...
    'Optimization method: Grid search'])
MetaOpts.EstimMethod = 'SpanLOO';
MetaOpts.Optim.Method = 'GS';
mySVC_Span_GS = uq_createModel(MetaOpts);

%%
% * Create an SVC model using the Smooth Span LOO error estimator
%   and the Cross-Entropy optimization method:
disp(['> Estimation Method: Smoothed LOO span estimate, ',...
    'Optimization method: CE'])
MetaOpts.EstimMethod = 'SmoothLOO';
MetaOpts.Optim.Method = 'CE';
mySVC_Smooth_CE = uq_createModel(MetaOpts);

%%
% * Create an SVC model using cross-validation (CV) error estimator
%   and the covariance matrix adapation-evolution strategy (CMA-ES)
%   optimization method:
disp(['> Estimation Method: Cross-Validation, ',...
    'Optimization method: CMA-ES'])
MetaOpts.EstimMethod = 'CV';
MetaOpts.Optim.Method = 'CMAES';
mySVC_CV_CMAES = uq_createModel(MetaOpts);

%% 5 - COMPARISON OF THE RESULTS

%%
% Generate a validation set:
Nval = 1e3;
Xval = uq_getSample(Nval);
Yval = uq_evalModel(myModel,Xval);

%%
% Generate data for plotting the true classifier:
Xplot = linspace(0,10,100)';
Yplot = Xplot .* sin(Xplot) + 1;

%% 5.1 - Case 1: Span LOO and Grid search
%
% Print a report on the main features of the SVC metamodel
% calibrated by Grid Search optimization:
uq_print(mySVC_Span_GS)

%%
% Visualize the SVC metamodel calibrated by Grid Search optimization
% (the true classifier is shown as the solid, colored line):
uq_display(mySVC_Span_GS)
hold on
uq_plot(Xplot,Yplot)
hold off

%%
% Compute the validation error for the SVC metamodel 
% calibrated by Grid Search optimization:
[Yclass_Span_GS,Ysvc_Span_GS] = uq_evalModel(mySVC_Span_GS,Xval);
Error_Span_GS = mean(Yval .* Yclass_Span_GS < 0)

%% 5.2 - Case 2: Smooth Span LOO and Cross-entropy optimization
%
% Print a report on the main features of the SVC metamodel calibrated
% by Cross-Entropy optimization:
uq_print(mySVC_Smooth_CE)

%%
% Visualize the SVC model calibrated by Cross-Entropy optimization
% (the true classifier is shown as the solid, colored line):
uq_display(mySVC_Smooth_CE)
hold on
uq_plot(Xplot,Yplot)
hold off

%%
% Compute the validation error for the SVC model calibrated
% by Cross-Entropy optimization:
[Yclass_Smooth_CE,Ysvc_Smooth_CE] = uq_evalModel(mySVC_Smooth_CE,Xval);
Error_Smooth_CE = mean(Yval.* Yclass_Smooth_CE < 0)

%% 5.3 - Case 3: Cross-validation and CMA-ES
%
% Print the main features of the SVC model calibrated by CMA-ES:
uq_print(mySVC_CV_CMAES)

%%
% Visualize the SVC model calibrated by CMA-ES
% (the true classifier is shown as the solid, colored line):
uq_display(mySVC_CV_CMAES)
hold on
uq_plot(Xplot,Yplot)
hold off

%%
% Compute the validation error for the SVC model calibrated by CMA-ES:
[Yclass_CV_CMAES,Ysvc_CV_CMAES] = uq_evalModel(mySVC_CV_CMAES,Xval);
Error_CV_CMAES = mean(Yval.* Yclass_CV_CMAES < 0)
