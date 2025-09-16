%% SVR METAMODELING: ONE-DIMENSIONAL EXAMPLE
%
% This example showcases how to perform Support Vector Machine
% for Regression (SVR) metamodeling on a simple one-dimensional function
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
% $$Y(x) = x \sin(x), \; x \in [0, 15]$$
%
% In UQLab, the model can be specified directly using a string,
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
% Specify the distribution of the input variables:
InputOpts.Marginals.Type = 'Uniform';
InputOpts.Marginals.Parameters = [0 15];

%%
% Create an INPUT object:
myInput = uq_createInput(InputOpts);

%% 4 - EXPERIMENTAL DESIGN AND MODEL RESPONSES
%
% An experimental design is generated and the corresponding model
% responses are calculated.
% These are later used for creating SVR metamodels
% with different kernel functions.
%
% Generate an experimental design of size $10$
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
% Use the experimental design generated above:
MetaOpts.ExpDesign.X = X;
MetaOpts.ExpDesign.Y = Y;

%%
% Select the L2-SVR method (mean-square loss function):
MetaOpts.Loss = 'l2-eps';

%%
% Use a hybrid genetic algorithm (GA) for optimizing the hyperparameters:
MetaOpts.Optim.Method = 'HGA';

%% 5.1 Matérn 5/2 kernel
%
% Select the 'Matern 5/2' kernel family:
MetaOpts.Kernel.Family = 'Matern-5_2';

%%
% Create the SVR metamodel:
mySVR_matern = uq_createModel(MetaOpts);

%% 
% Print a report on the main features of the resulting L2-SVR model:
uq_print(mySVR_matern)

%%
% Visualize the SVR predictor and the $95\%$ confidence bounds:
uq_display(mySVR_matern)

%%
% Note that the |uq_display| functionality is only available
% for one- and two-dimensional functions.

%% 5.2 Gaussian kernel
%
% Create another SVR metamodel using a Gaussian kernel:
MetaOpts.Kernel.Family = 'Gaussian';

mySVR_exp = uq_createModel(MetaOpts);

%% 5.3 User-defined kernel
%
% A user-defined (custom) kernel is built up as a mixture of a Gaussian
% kernel and a polynomial kernel:
%
% $$
% k(x,x') = \theta_3 \cdot \exp\left(\frac{||x-x'||^2}{(2\, \theta_1)^2}\right) + (1-\theta_3) \cdot (x \cdot x' + \theta_2 )^5
% $$
%
% It is defined using a handle to a function written in an m-file
% (shipped with UQLab):
MetaOpts.Kernel.Handle = @uq_MixedSVRKernel;

%% 
% Initialize the parameters of the kernel:
MetaOpts.Hyperparameters.theta = [0.5 1 0.5];

%%
% Set bounds on the search space for the hyperparameters calibration:
MetaOpts.Optim.Bounds.C = [10; 1000];
MetaOpts.Optim.Bounds.epsilon = [1e-3; 1];
MetaOpts.Optim.Bounds.theta = [0.1 1e-3 1e-3; 5 10 1];

%%
% Create the SVR metamodel with custom kernel:
mySVR_cusK = uq_createModel(MetaOpts);

%% 6 - VALIDATION OF THE METAMODELS
%
% Create a validation sample:
Nval = 1e3;
Xval = linspace(0, 15, Nval)';

%%
% Evaluate the model at the validation sample points:
Yval = uq_evalModel(myModel,Xval);

%%
% Evaluate the corresponding predictions for each
% of the three SVR metamodels:
Y_mat = uq_evalModel(mySVR_matern,Xval);
Y_exp = uq_evalModel(mySVR_exp,Xval);
Y_cusK = uq_evalModel(mySVR_cusK,Xval);

%%
% Create a comparative plot of the SVR predictor of each metamodel
% as well as the output of the true model:
uq_figure
uq_plot(...
    Xval, Yval, 'k',...
    Xval, Y_mat,...
    Xval, Y_exp,...
    Xval, Y_cusK,...
    X, Y, 'ko')

axis([0 15 -20 20])
xlabel('$\mathrm X$')
ylabel('$\mathrm{\widehat{Y}(x)}$')
uq_legend(...
    {'Full model',...
        'Mat{\''e}rn 5/2',...
        'Exponential',...
        'Custom kernel',...
        'Observations'},...
    'Location', 'southwest')
