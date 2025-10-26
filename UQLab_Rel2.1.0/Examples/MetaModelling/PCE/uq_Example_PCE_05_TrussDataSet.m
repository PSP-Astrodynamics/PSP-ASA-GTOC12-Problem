%% PCE METAMODELING: TRUSS DATA SET
%
% This example showcases how to perform polynomial chaos expansion (PCE)
% metamodeling using existing data sets.
% The data sets come from a finite element model of a truss structure
% and are retrieved from different MAT-files.
% The files consist of an experimental design of size $200$
% and a validation basis of size $10^4$.
%
% More information about the truss structure model can be found in the
% |README.txt| file located in the same folder as the truss data set.

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
FILELOCATION = fullfile(uq_rootPath, 'Examples', 'SimpleDataSets',...
    'Truss_Matlab_FEM');

%%
% Read the experimental design data set file and store the contents 
% in matrices:
load(fullfile(FILELOCATION,'Truss_Experimental_Design.mat'), 'X', 'Y');

%%
% Read the validation basis data set file and store the contents
% in matrices:
load(fullfile(FILELOCATION,'Truss_Validation_Basis.mat'), 'Xval', 'Yval');

%% 3 - INPUT MODEL
%
% Because PCE requires a choice of polynomial basis,
% a probabilistic input model needs to be defined.
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

%% 4 - POLYNOMIAL CHAOS EXPANSION (PCE) METAMODEL
%
% Select PCE as the metamodeling tool:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'PCE';

%% 
% Use experimental design loaded from the data files:
MetaOpts.ExpDesign.X = X;
MetaOpts.ExpDesign.Y = Y;

%%
% Set the maximum polynomial degree to 5:
MetaOpts.Degree = 1:5;

%%
% Provide the validation data set to get the validation error:
MetaOpts.ValidationSet.X = Xval;
MetaOpts.ValidationSet.Y = Yval;

%%
% Create the metamodel object and add it to UQLab:
myPCE = uq_createModel(MetaOpts);

%% 
% Print a summary of the resulting PCE metamodel:
uq_print(myPCE)
    
%% 5 - VALIDATION
%
% Evaluate the PCE metamodel at the validation set points:
YPCE = uq_evalModel(myPCE,Xval);

%%
% Plot histograms of the true output and the PCE prediction:
uq_figure

cmap = uq_colorOrder(2);
uq_histogram(Yval, 'FaceColor', cmap(1,:))
hold on
uq_histogram(YPCE, 'FaceColor', cmap(2,:))
hold off

xlabel('$\mathrm{Y}$')
ylabel('Counts')
uq_legend(...
    {'True model response', 'PCE prediction'},...
    'Location', 'northwest')

%% 
% Plot the true vs. predicted values:
uq_figure

uq_plot(Yval, YPCE, '+')
hold on
uq_plot([min(Yval) max(Yval)], [min(Yval) max(Yval)], 'k')
hold off

axis equal 
axis([min(Yval) max(Yval) min(Yval) max(Yval)]) 

xlabel('$\mathrm{Y_{true}}$')
ylabel('$\mathrm{Y_{PCE}}$')

%%
% Print the validation and leave-one-out (LOO) cross-validation errors:
fprintf('PCE metamodel validation error: %5.4e\n', myPCE.Error.Val)
fprintf('PCE metamodel LOO error:        %5.4e\n', myPCE.Error.LOO)
