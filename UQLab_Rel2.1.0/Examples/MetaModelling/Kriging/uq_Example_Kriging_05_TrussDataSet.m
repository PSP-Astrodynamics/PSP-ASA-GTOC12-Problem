%% KRIGING METAMODELING: TRUSS DATA SET
%
% This example showcases how to perform Kriging metamodeling
% using existing data sets.
% The data sets come from a finite element model of a truss structure
% and are retrieved from different MAT-files.
% The files consist of an experimental design of size $200$
% and a validation set of size $10^4$.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace 
% and initialize the UQLab framework:
clearvars
uqlab

%% 2 - RETRIEVE DATA SETS
%
% The experimental design and the validation basis are stored
% in two separate files in the following location:
FILELOCATION = fullfile(...
    uq_rootPath, 'Examples', 'SimpleDataSets', 'Truss_Matlab_FEM');

%%
% Read the experimental design data set file and store the contents 
% in matrices:
load(fullfile(FILELOCATION,'Truss_Experimental_Design.mat'), 'X', 'Y');

%%
% Read the validation basis data set file and store the contents
% in matrices:
load(fullfile(FILELOCATION,'Truss_Validation_Basis.mat'), 'Xval', 'Yval');

%% 3 - KRIGING METAMODEL
%
% Select Kriging as the metamodeling tool:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'Kriging';

%% 
% Use experimental design loaded from the data files:
MetaOpts.ExpDesign.X = X;
MetaOpts.ExpDesign.Y = Y;

%%
% Use maximum-likelihood to estimate the hyperparameters:
MetaOpts.EstimMethod = 'ML';

%%
% Use the built-in covariance-matrix adaptation evolution strategy
% optimization algorithm (CMAES) for estimating the hyperparameters:
MetaOpts.Optim.Method = 'CMAES';

%%
% Provide the validation data set to get the validation error:
MetaOpts.ValidationSet.X = Xval;
MetaOpts.ValidationSet.Y = Yval;

%%
% Create the Kriging metamodel:
myKriging = uq_createModel(MetaOpts);

%% 
% Print a summary of the resulting Kriging metamodel:
uq_print(myKriging)

%% 4 - VALIDATION

%%
% Evaluate the Kriging metamodel at the validation set:
YKrg = uq_evalModel(myKriging,Xval);

%%
% Plot histograms of the true output and the Kriging prediction:
uq_figure

cmap = uq_colorOrder(2);
uq_histogram(Yval, 'FaceColor', cmap(1,:))
hold on
uq_histogram(YKrg, 'FaceColor', cmap(2,:))
hold off

uq_legend(...
    {'True model response', 'Kriging prediction'},...
    'Location', 'northwest')

xlabel('$\mathrm{Y}$')
ylabel('Counts')

%% 
% Plot the true vs. predicted values:
uq_figure

uq_plot(Yval, YKrg, '+')
hold on 
uq_plot([min(Yval) max(Yval)], [min(Yval) max(Yval)],'k')
hold off

axis equal 
axis([min(Yval) max(Yval) min(Yval) max(Yval)]) 

xlabel('$\mathrm{Y_{true}}$')
ylabel('$\mathrm{Y_{Krg}}$')

%%
% Print the validation and leave-one-out (LOO) cross-validation errors:
fprintf('Kriging metamodel validation error: %5.4e\n',myKriging.Error.Val)
fprintf('Kriging metamodel LOO error:        %5.4e\n',myKriging.Error.LOO)