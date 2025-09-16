%% GENERALIZED LAMBDA METAMODELING - MULTIPLE OUTPUTS
%
% This example showcases how to build a generalized lambda model (GLaM)
% to represent the distribution of the end-time and average values of 
% a geometric Brownian motion

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
% $dS_t(\mathbf{x}) = x_1 S_t + x_2 dW_t$ 
%
% with boundary condition $S_0(\mathbf{x}) = 1$.
% The value at time 1 and the average value (over time [0,1]) are of interest, i.e., 
%
% $Y_1 = S_1(\mathbf{x})$ and $Y_2 = \int_0^1 S_t(\mathbf{x}) dt$
% 
% Create a MODEL object from the |uq_GBM_MultiOutputs| function:
ModelOpts.mFile = 'uq_GBM_MultiOutputs';
ModelOpts.isStochastic = true;% the model is stochastic
ModelOpts.isVectorized = true;% the model is vectorized
myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of
% three independent random variables:
%
% $X_1 \sim \mathcal{U}(0, 0.1), X_2 \sim \mathcal{U}(0.1, 0.4)$

InputOpt.Marginals(1).Type = 'Uniform';
InputOpt.Marginals(1).Parameters = [0,0.1];
InputOpt.Marginals(2).Type = 'Uniform';
InputOpt.Marginals(2).Parameters = [0.1,0.4];

% Create an INPUT object based on the marginals:
myInput = uq_createInput(InputOpt);

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

% Use an experimental design of size 1000
MetaOpts.ExpDesign.NSamples = 1000;

% Create the GLaM
myGLaM = uq_createModel(MetaOpts);

%% 5 - VISUALIZATION

% Define the points to visualize the associated PDFs
X4plot = [0.07,0.13
          0.02,0.33];

% Evaluate the stochastic simulator to get the reference histograms
R = 1e3; % number of replications
Y4plot = uq_evalModel(myModel,X4plot,R);

% Generate samples from the GLaM
Y4plotGLaM = uq_evalModel(myGLaM,X4plot,R);

% Evaluate the lambda's on the plotting points
lambda = uq_GLaM_evalLambda(myGLaM,X4plot);

% loop over the output
for oo = 1:myGLaM.Internal.Runtime.Nout
    [yplot,xplot]=uq_GLD_DistributionFunc(lambda(:,oo,:),'pdf');
    for ix = 1:size(X4plot,1)
        uq_figure('name',sprintf('Output #%i',oo))
        uq_histogram(squeeze(Y4plot(ix,oo,:)),'normalized','pdf');
        hold on
        uq_histogram(squeeze(Y4plotGLaM(ix,oo,:)),'normalized','pdf','FaceAlpha',0.5);    
        uq_plot(xplot(ix,:), yplot(ix,:));
        hold off
        uq_legend({'Reference','GLaM samples','GLaM PDF'});
        title(sprintf('PDF at point [%1.2f,%1.2f]',X4plot(ix,:)),...
        'FontSize', 16,'Interpreter', 'LaTeX');
        xlabel(sprintf('$Y_%d$',oo),'Interpreter','latex')
    end
end

%% 6 - VALIDATION

% Create a validation set:
Nval = 2e2;
Xval = uq_getSample(myInput,Nval,'LHS');
Yval = uq_evalModel(myModel,Xval,1e3);% use 1e3 replications to represent the response distribution

% Evaluate some metrics of the metamodel at the validation set:
valMetrics = uq_GLaM_evalModelSampleMetrics(myGLaM,Xval,Yval);
for oo = 1:length(valMetrics)
    fprintf('The validation normalized Wasserstein distance for output%d is %1.3e. \n',oo,valMetrics(oo).NormalizedWSD);
end
