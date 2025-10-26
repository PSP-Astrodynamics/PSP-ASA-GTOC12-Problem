%% STOCHASTIC POLYNOMIAL CHAOS EXPANSIONS - BIMODAL RESPONSE
%
% This example showcases how to build a stochastic polynomial chaos expansion (SPCE)
% to represent a 1-d stochastic simulator

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars;
uqlab;
rng(100,'twister')

%% 2 - COMPUTATIONAL MODEL
%
% The response distribtution of the one-dimensional bimodal distribution
% is a Gaussian mixture, defined as
%
% $f(y|x) = 0.5 \varphi\left(1.25y-(5\sin^2(\pi \cdot x)+5x-2.5)\right) + 0.75\varphi\left(1.25y-(5\sin^2(\pi \cdot x)-5x+2.5)\right)$
% 
% Implemented in the |uq_1dbimodal(X)| function supplied with UQLab.
% The function evaluates the inputs gathered in the $N \times M$ matrix
% |X|, where $N$ and $M$ are the numbers of realizations and input
% variables, respectively.
% 
% Create a MODEL object from the |uq_1dbimodal| function:
ModelOpts.mFile = 'uq_1dbimodal';
ModelOpts.isStochastic = true;% the model is stochastic
ModelOpts.isVectorized = true;% the model is vectorized 
ModelOpts.stochasticSim.supportRep = true;% the model supports replications
myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of
% one uniform random variable:
% 
% $X_1 \sim \mathcal{U}(0, 1)$

InputOpt.Marginals(1).Type = 'Uniform';
InputOpt.Marginals(1).Parameters = [0,1];

% Create an INPUT object based on the marginals:
myInput = uq_createInput(InputOpt);

%% 4 - STOCHASTIC POLYNOMIAL CHAOS EXPANSIONS
%
% Select the metamodeling tool and the SPCE module:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'SPCE';

% Configure UQLab to generate an experimental design of size $800$
% based on the latin hypercube sampling:
MetaOpts.ExpDesign.NSamples = 800;
MetaOpts.ExpDesign.Sampling = 'LHS';

% Create the surrogate:
mySPCE = uq_createModel(MetaOpts);

%% 5 - FAST ASSESSMENT OF THE METAMODEL

% Print some basic information:
uq_print(mySPCE);
% 
% Display the model: pseudocolor plot of the
% mean and standard deviation of the SPCE
uq_display(mySPCE);

%% 6 - VISUALIZATION

% Define the points to visualize the associated PDFs
X4plot = [0.2;0.5;0.7;0.9];

% Evaluate the stochastic simulator to get the reference histograms
R = 1e4; % number of replications
Y4plotRef= uq_evalModel(myModel,X4plot,R);

% Generate samples from the surrogate
Y4plotSPCE = uq_evalModel(mySPCE,X4plot,R);

for ix = 1:size(X4plot,1)
    uq_figure()
    uq_histogram(squeeze(Y4plotRef(ix,1,:)),'normalized','pdf');    
    hold on
    uq_histogram(squeeze(Y4plotSPCE(ix,1,:)),'normalized','pdf','FaceAlpha',0.5);    
    hold off
    uq_legend({'Reference','SPCE samples'});
    title(sprintf('Response PDF for x=%1.2f',X4plot(ix,:)),...
        'FontSize', 16,...
        'Interpreter', 'LaTeX');
    xlabel('y')
end

%% 7 - VALIDATION
% 
% Create a validation set:
Nval = 1e2;
Xval = uq_getSample(myInput,Nval,'LHS');
Yval = uq_evalModel(myModel,Xval,1e3);% use 1e3 replications to represent the response distribution

% Evaluate some metrics of the metamodel at the validation set:
valMetrics = uq_SPCE_evalModelSampleMetrics(mySPCE,Xval,Yval);
fprintf('The validation normalized Wasserstein distance is %1.3e. \n',valMetrics.NormalizedWSD);