%% STOCHASTIC POLYNOMIAL CHAOS EXPANSIONS: SIR DATA SET
%
% This example showcases how to build a stochastic polynomial chaos expansion (SPCE)
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

% Because the dataset is quite large, we will only use a limited number of
% replications of the model outputs for validation (calculation of error
% metrics can be memory consuming)
Yval = Yval(:,:,1:1000);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of
% two independent uniform random variables:
%
inputOpt.Marginals(1).Name = 'S0'; % initial number of susceptible individuals
inputOpt.Marginals(1).Type = 'Uniform';
inputOpt.Marginals(1).Parameters = [1200, 1800];
inputOpt.Marginals(2).Name = 'I0'; % initial number of infected individuals
inputOpt.Marginals(2).Type = 'Uniform';
inputOpt.Marginals(2).Parameters = [20, 200];

% Create an INPUT object based on the marginals:
myInput = uq_createInput(inputOpt);

%% 4 - BUILD THE STOCHASTIC POLYNOMIAL CHAOS EXPANSION

% Select the metamodeling tool and the SPCE module:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'SPCE';

% Define the degrees
MetaOpts.Degree = 1:3;

% Define the truncation scheme
MetaOpts.TruncOptions.qNorm = [0.5,0.75,1];

% Set mean estimation
% Here, the mean function is fit independent of the degree and 
% qNorm adaptation (by default, it is turned on)
MetaOpts.MeanReg.separateFit = true;
MetaOpts.MeanReg.Method = 'LARS';% fitting method
MetaOpts.MeanReg.Degree = 0:5;% degree
MetaOpts.MeanReg.TruncOptions.qNorm = 0.4:0.2:1;% qnorm

% Use experimental design loaded from the data files:
MetaOpts.ExpDesign.X = Xtrain;
MetaOpts.ExpDesign.Y = Ytrain;

% Provide the validation data set to get the validation error:
MetaOpts.ValidationSet.X = Xval;
MetaOpts.ValidationSet.Y = Yval(:,:,1:100); 

% Create the SPCE
mySPCE = uq_createModel(MetaOpts);

%% 5 - FAST ASSESSMENT OF THE METAMODEL

% Print some basic information:
uq_print(mySPCE);

% Display the model: pseudocolor plot of the
% mean and standard deviation of the SPCE
uq_display(mySPCE);

%% 6 - VISUALIZATION

% Select the points to visualize the associated PDFs
Nplot = 4;% number of plotting points
plotind = randi([1,100],[1,Nplot]);
X4plot = Xval(plotind,:);

% Retrieve the reference values
Y4plot = Yval(plotind,1,:);

% Generate samples from the surrogate
Y4plotSPCE = uq_evalModel(mySPCE,X4plot,1e3);

for ix = 1:Nplot
    uq_figure()
    uq_histogram(squeeze(Y4plot(ix,1,:)),'normalized','pdf');    
    hold on
    uq_histogram(squeeze(Y4plotSPCE(ix,1,:)),'normalized','pdf','FaceAlpha',0.5);    
    hold off
    uq_legend({'Reference','SPCE samples'});
    title(sprintf('PDF at point [%d,%d]',X4plot(ix,:)),...
        'FontSize', 16,...
        'Interpreter', 'LaTeX');
end
