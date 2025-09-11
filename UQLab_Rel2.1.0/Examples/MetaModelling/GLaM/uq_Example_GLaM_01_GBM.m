%% GENERALIZED LAMBDA METAMODELING
%
% This example showcases how to build a generalized lambda model (GLaM)
% to represent the distribution of the end time value of a geometric Brownian motion

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars;
uqlab;
rng(100,'twister')

%% 2 - COMPUTATIONAL MODEL
%
% The geometric Brownian motion is defined as:
%
% $$dS_t(\mathbf{x}) = x_1 S_t + x_2 dW_t$$
% with the boundary condition $S_0(\mathbf{x}) = 1$.
% The value at time 1 is of interest, i.e., $Y = S_1(\mathbf{x})$
%
% This computation is carried out by the function
% |uq_GBM(X)| supplied with UQLab.
% The function evaluates the inputs gathered in the $N \times M$ matrix
% |X|, where $N$ and $M$ are the numbers of realizations and input
% variables, respectively.
% 
% Create a MODEL object from the |uq_GBM| function:
ModelOpts.mFile = 'uq_GBM';
ModelOpts.isStochastic = true;% the model is stochastic
ModelOpts.isVectorized = true;% the model is vectorized 
ModelOpts.stochasticSim.supportRep = true;% the model supports replications
myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of
% two independent uniform random variables:
%
% $X_1 \sim \mathcal{U}(0, 0.1), X_2 \sim \mathcal{U}(0.1, 0.4)$

InputOpt.Marginals(1).Type = 'Uniform';
InputOpt.Marginals(1).Parameters = [0,0.1];
InputOpt.Marginals(2).Type = 'Uniform';
InputOpt.Marginals(2).Parameters = [0.1,0.4];

% Create an INPUT object based on the marginals:
myInput = uq_createInput(InputOpt);

%% 4 - GENERALIZED LAMBDA METAMODEL
%
% Select the metamodeling tool and the GLaM module:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'GLaM';


% Specify the fitting method (i.e., maximum likelihood estimation with 
% full basis selection for $\lambda_3$ and $\lambda_4$):
MetaOpts.Method = 'FullReg';

% Specify the number of samples to be 
% Configure UQLab to generate an experimental design of size $800$
% based on the latin hypercube sampling:
MetaOpts.ExpDesign.NSamples = 800;
MetaOpts.ExpDesign.Sampling = 'LHS';

% Create the GLaM:
myGLaM = uq_createModel(MetaOpts);

%% 5 - FAST ASSESSMENT OF THE GLAM

% Print some basic information:
uq_print(myGLaM);

% Display the model: pseudocolor plot of the
% mean and standard deviation of the GLaM
uq_display(myGLaM);

% Display the model: pseudocolor plot of the
% lambda's of the GLaM
uq_display(myGLaM,'lambda');

%% 6 - VISUALIZATION

% Define the points to visualize the associated PDFs
X4plot = [0.07,0.13
    0.04,0.12
    0.05,0.3
    0.02,0.33];

% Generate samples from the GLaM
R = 1e5; % number of replications
Y4plotGLaM = uq_evalModel(myGLaM,X4plot,R);

% Evaluate the lambda's on the plotting points
lambda = uq_GLaM_evalLambda(myGLaM,X4plot);
% get the pdf plots for these lambda's
[yplot,xplot]=uq_GLD_DistributionFunc(lambda,'pdf');

% Evaluate the stochastic simulator to get the reference histograms
Y4plotRef= uq_evalModel(myModel,X4plot,R);

for ix = 1:size(X4plot,1)
    uq_figure()
    uq_histogram(squeeze(Y4plotRef(ix,1,:)),'normalized','pdf');    
    hold on
    uq_histogram(squeeze(Y4plotGLaM(ix,1,:)),'normalized','pdf','FaceAlpha',0.5);    
    uq_plot(xplot(ix,:), yplot(ix,:));
    hold off
    uq_legend({'Reference','GLaM samples','GLaM PDF'});
    title(sprintf('PDF at point [%1.2f,%1.2f]',X4plot(ix,:)),...
        'FontSize', 16,...
        'Interpreter', 'LaTeX');
    xlabel('Y','Interpreter','Latex')
end

%% 7 - VALIDATION

% Create a validation set:
Nval = 1e3;
Xval = uq_getSample(myInput,Nval,'LHS');
Yval = uq_evalModel(myModel,Xval,1e4);% use 1e4 replications to represent the response distribution

% Evaluate some metrics of the metamodel at the validation set:
valMetrics = uq_GLaM_evalModelSampleMetrics(myGLaM,Xval,Yval);
fprintf('The validation normalized Wasserstein distance is %1.3e. \n',valMetrics.NormalizedWSD);
