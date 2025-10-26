%% PC-KRIGING METAMODELING: TRUSS DATA SET
%
% This example showcases how to perform polynomial chaos-Kriging
% (PC-Kriging) metamodeling using existing data sets.
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

%% 3 - PROBABILISTIC INPUT MODEL
%
% Due to the use of polynomial chaos as trend, a probabilistic input model 
% has to be specified for the PC-Kriging metamodel.
% Specify the marginals of the probabilistic input model:

% Young's modulus of cross-sections
for i=1:2
    InputOpts.Marginals(i).Name = sprintf('E%d',i);
    InputOpts.Marginals(i).Type = 'Lognormal';    
    InputOpts.Marginals(i).Moments = [2.1e11 2.1e10];  
end

% Cross-section of horizontal elements
InputOpts.Marginals(3).Name = 'A1';
InputOpts.Marginals(3).Type = 'Lognormal';
InputOpts.Marginals(3).Moments = [2.0e-3 2.0e-4];

% Cross-section of diagonal elements
InputOpts.Marginals(4).Name = 'A2';
InputOpts.Marginals(4).Type = 'Lognormal' ;
InputOpts.Marginals(4).Moments = [1.0e-3 1.0e-4];

% Loads on the node of top chord
for i = 5:10
    InputOpts.Marginals(i).Name = sprintf('P%d',i-4);
    InputOpts.Marginals(i).Type = 'Gumbel';    
    InputOpts.Marginals(i).Moments = [5.0e4 7.5e3];  
end

%%
% Create an INPUT object based on the specified marginals:
myInput = uq_createInput(InputOpts);

%% 4 - PC-KRIGING METAMODEL
%
% Select |PCK| as the metamodeling tool and |sequential| as its mode:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'PCK';
MetaOpts.Mode = 'sequential';

%% 
% Use experimental design loaded from the data files:
MetaOpts.ExpDesign.X = X;
MetaOpts.ExpDesign.Y = Y;

%%
% Use the covariance matrix adaptation-evolution strategy (CMA-ES)
% optimization algorithm (built in UQLab)
% for the hyperparameters estimation of the Kriging part
% of the PC-Kriging metamodel:
MetaOpts.Kriging.Optim.Method = 'CMAES';

%%
% Set the maximum polynomial degree of the polynomial chaos expansion 
% (PCE) trend to $5$:
MetaOpts.PCE.Degree = 1:5;

%%
% Provide the validation data set to get the validation error:
MetaOpts.ValidationSet.X = Xval;
MetaOpts.ValidationSet.Y = Yval;

%%
% Create the PC-Kriging metamodel:
myPCK = uq_createModel(MetaOpts);

%% 
% Print a summary of the resulting PC-Kriging metamodel:
uq_print(myPCK)

%% 5 - VALIDATION
%
% Evaluate the PC-Kriging metamodel at the validation set points:
YPCK = uq_evalModel(myPCK,Xval);

%%
% Plot histograms of the true output and the PC-Kriging prediction:
uq_figure

cmap = uq_colorOrder(2);
uq_histogram(Yval, 'FaceColor', cmap(1,:))
hold on
uq_histogram(YPCK, 'FaceColor', cmap(2,:))
hold off

uq_legend(...
    {'True model response', 'PCK prediction'},...
    'Location', 'northwest')

xlabel('$\mathrm{Y}$')
ylabel('Counts')

%% 
% Plot the true vs. predicted values:
uq_figure

uq_plot(Yval, YPCK, '+')
hold on
uq_plot([min(Yval) max(Yval)], [min(Yval) max(Yval)], 'k')
hold off

axis equal
axis([min(Yval) max(Yval) min(Yval) max(Yval)]) 

xlabel('$\mathrm{Y_{true}}$')
ylabel('$\mathrm{Y_{PCK}}$')

%%
% Print the validation and leave-one-out (LOO) cross-validation errors:
fprintf('PCK metamodel validation error: %5.4e\n',myPCK.Error.Val)
fprintf('PCK metamodel LOO error:        %5.4e\n',myPCK.Error.LOO)
