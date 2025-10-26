%% SVC METAMODELING: FISHER'S IRIS DATA SET
%
% This example showcases how to perform Support Vector Machines for 
% Classification (SVC) metamodeling on a simple two-dimensional data set,
% using various types of kernel functions: Gaussian, linear,
% Matérn 5/2, and custom (a mixture of a Gaussian kernel
% and a second-order polynomial kernel).

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace,
% set the random number generator for reproducible results,
% and initialize the UQLab framework:
clearvars
rng(1,'twister')
uqlab

%% 2 - RETRIEVE DATA SET
%
% The Fisher's iris data set is stored in a MAT-file
% in the following location:
FILELOCATION = fullfile(...
    uq_rootPath, 'Examples', 'SimpleDataSets', 'Fisher_Iris');

%%
% Read the data set and store the contents in matrices:
load(fullfile(FILELOCATION,'fisher_iris_reduced.mat'), 'X', 'Y')

%%
% The data is stored in the variables |X| and |Y|.
% The two features (input or dependent variables) are the sepal width
% and length and they are stored in the variable |X|.
% In the dependent variable (output) |Y|,
% the label *-1* represents the *virginica* species
% while the label *1* represents the *versicolor* species.
% The data set contains $100$ points.

%% 3 - SVC METAMODELS
%
% Select the metamodeling tool and the SVC module:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'SVC';

%% 
% Assign the data set loaded above to the metamodel options:
MetaOpts.ExpDesign.X = X;
MetaOpts.ExpDesign.Y = Y;

%%
% Select a linear penalization:
MetaOpts.Penalization = 'linear';

%%
% Use the span leave-one-out (LOO) error estimate
% to calibrate the kernel hyperparameters:
MetaOpts.EstimMethod = 'SpanLOO';

%%
% Use the cross-entropy method for the optimization:
MetaOpts.Optim.Method = 'CE';

%%
% Using the same options above, several SVC metamodels are created using
% different kernel families.

%% 3.1 Gaussian kernel
%
% Select the Gaussian kernel family:
MetaOpts.Kernel.Family = 'Gaussian';

%%
% Create the SVC metamodel:
mySVC_gau = uq_createModel(MetaOpts);

%% 
% Print a report on the resulting SVC metamodel:
uq_print(mySVC_gau)

%%
% Create a plot of the SVC predictor:
uq_display(mySVC_gau)

%%
% Note that the |uq_display| functionality is only available
% for two-dimensional functions.

%% 3.2 Linear kernel
%
% Create another SVC metamodel using a linear (non-stationary) kernel:
MetaOpts.Kernel.Family = 'linear_NS';
mySVC_lin = uq_createModel(MetaOpts);

%% 
% Print a report on the main features of the resulting SVC metamodel
% (linear kernel):
uq_print(mySVC_lin)

%%
% Create a plot of the SVC predictor (linear kernel):
uq_display(mySVC_lin)

%% 3.3 Matérn-5/2 kernel
%
% Create another SVC metamodel using a 'Matérn-5/2' kernel:
MetaOpts.Kernel.Family = 'matern-5_2';
mySVC_mat = uq_createModel(MetaOpts);

%% 
% Print a report on the main features of the resulting SVC metamodel
% (Matérn-5/2 kernel):
uq_print(mySVC_mat)

%%
% Create a plot of the SVC predictor (Matérn-5/2 kernel):
uq_display(mySVC_mat)

%% 3.4 User-defined kernel
%
% A user-defined (custom) kernel is built up as a mixture of a Gaussian
% kernal and a polynomial kernel:
%
% $k(x,x') = \theta_3 \cdot \exp[||x-x'||^2/ ( 2\, \theta_1)^2 ] + (1-\theta_3) \cdot (x \cdot x' + \theta_2 )^5$
%
% It is defined  through a handle to a function written in an m-file
% (shipped with UQLab):
MetaOpts.Kernel.Handle = @uq_MixedSVRKernel;

%% 
% Initialize the hyperparameters of the kernel:
MetaOpts.Hyperparameters.theta = [0.5 0.5 0];

%%
% Set the bounds on the search space for the hyperparameters calibration: 
MetaOpts.Optim.Bounds.C = [10; 1000];
MetaOpts.Optim.Bounds.theta = [0.1 1 1e-3; 5 5 1];

%%
% Create the SVC metamodel with the custom kernel:
mySVC_cusK = uq_createModel(MetaOpts);

%% 
% Print a report on the main features of the resulting SVC metamodel
% (custom kernel):
uq_print(mySVC_cusK)

%%
% Create a plot of the SVC predictor (custom kernel):
uq_display(mySVC_cusK)
