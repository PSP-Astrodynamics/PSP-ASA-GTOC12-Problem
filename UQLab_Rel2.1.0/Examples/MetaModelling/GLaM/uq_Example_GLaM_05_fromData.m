%% GENERALIZED LAMBDA METAMODELING: SIR DATA SET
%
% This example showcases how to build a generalized lambda model (GLaM)
% using existing data sets.
% The data sets come from a stochastic susceptible-infected-recovered
% model.
% The files consist of an experimental design of size $500$
% and a validation set of size $10^2$ and $10^4$ replications.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars;
uqlab;
rng(100,'twister')
%% 2 - RETRIEVE DATA SETS
%
% The experimental design and the validation basis are stored
% in two separate files in the following location:
FILELOCATION = fullfile(...
    uq_rootPath, 'Examples', 'SimpleDataSets', 'StochasticSIR');

% Read the data set file and store the contents in matrices:
load(fullfile(FILELOCATION,'SIR2d.mat'), 'Xtrain', 'Ytrain', 'Xval', 'Yval');

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of
% two independent random variables:

inputOpt.Marginals(1).Name = 'S0'; % initial number of susceptible individuals
inputOpt.Marginals(1).Type = 'Uniform';
inputOpt.Marginals(1).Parameters = [1200, 1800];
inputOpt.Marginals(2).Name = 'I0'; % initial number of infected individuals
inputOpt.Marginals(2).Type = 'Uniform';
inputOpt.Marginals(2).Parameters = [20, 200];

% Create an INPUT object based on the marginals:
myInput = uq_createInput(inputOpt);

%% 4 - BUILD THE GENERALIZED LAMBDA METAMODEL

% Select the metamodeling tool and the GLaM module:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'GLaM';

% Specify the range for the univariate polynomials 
% degree selection and truncation schemes
% for the lambda parameters
MetaOpts.Lambda(1).Degree=0:5;
MetaOpts.Lambda(1).TruncOptions.qNorm=0.2:0.2:0.8;
MetaOpts.Lambda(2).Degree=0:3;
MetaOpts.Lambda(2).TruncOptions.qNorm=0.2:0.2:0.8;
MetaOpts.Lambda(3).Degree=0:2;
MetaOpts.Lambda(3).TruncOptions.qNorm=0.2:0.2:0.8;
MetaOpts.Lambda(4).Degree=0:2;
MetaOpts.Lambda(4).TruncOptions.qNorm=0.2:0.2:0.8;

% Use experimental design loaded from the data files:
MetaOpts.ExpDesign.X = Xtrain;
MetaOpts.ExpDesign.Y = Ytrain;

% Provide the validation data set to get the validation error:
MetaOpts.ValidationSet.X = Xval;
MetaOpts.ValidationSet.Y = Yval;

% Create the GLaM
myGLaM = uq_createModel(MetaOpts);

%% 5 - FAST ASSESSMENT OF THE METAMODEL

% Print some basic information:
uq_print(myGLaM);

% Display the model: pseudocolor plot of the
% mean and standard deviation of the GLaM
uq_display(myGLaM);

%% 6 - VISUALIZATION

% Select the points to visualize the associated PDFs
Nplot = 4;% number of plotting points
plotind = randi([1,100],[1,Nplot]);
X4plot = Xval(plotind,:);

% Retrieve the reference values
Y4plot = Yval(plotind,1,:);

% Evaluate the lambda's on the plotting points
lambda = uq_GLaM_evalLambda(myGLaM,X4plot);
% Compute the PDF plots
[yplot,xplot]=uq_GLD_DistributionFunc(lambda,'pdf');

for ix = 1:Nplot
    uq_figure()
    uq_histogram(squeeze(Y4plot(ix,1,:)),'normalized','pdf');    
    hold on
    uq_plot(xplot(ix,:), yplot(ix,:));
    hold off
    uq_legend({'Reference','GLaM prediction'});
    title(sprintf('PDF at point [%d,%d]',X4plot(ix,:)),...
        'FontSize', 16,...
        'Interpreter', 'LaTeX');
    xlabel('Y','Interpreter','Latex')    
end
