%% KRIGING RESAMPLING: ONE-DIMENSIONAL EXAMPLE
%
% This example showcases how to sample Kriging trajectories.
% When enabling resampling, UQLab creates an internal random field using
% the Kriging posterior mean and covariance. This random field is then
% discretized using EOLE or KL to sample trajectories.

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
% $$Y = x \sin(x), \; x \in [0, 15]$$
%
% In UQLab, the model can be specified directly as a string,
% written below in a vectorized operation:
ModelOpts.mString = 'X.*sin(X)';
ModelOpts.isVectorized = true;

myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of a single 
% uniform random variable:
%
% $$X \sim \mathcal{U}(0, 15)$$

%%
% Specify the probabilistic model of the input variable:
InputOpts.Marginals.Type = 'Uniform';
InputOpts.Marginals.Parameters = [0 15];

%%
% Then create an INPUT object:
myInput = uq_createInput(InputOpts);

%% 4 - EXPERIMENTAL DESIGN AND MODEL RESPONSES
%
% Generate an experimental design $X$ of size $8$ 
% using the latin hypercube sampling (LHS):
X = uq_getSample(8,'LHS');

%%
% Evaluate the corresponding model responses:
Y = uq_evalModel(X) ;

%% 5 - KRIGING MODEL
%
% Select the metamodeling tool and the Kriging module:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'Kriging';

%% 
% Set the experimental design
MetaOpts.ExpDesign.X = X;
MetaOpts.ExpDesign.Y = Y;

%%
% Select Maximum likelihood as estimation method
MetaOpts.EstimMethod = 'ML';

%%
% Enable trajectories sampling by setting this option to true
MetaOpts.isTrajectory = true ;

%% 
% Define the domain in which the random field used for resampling is
% discretized
MetaOpts.GRF.Domain = [0; 15] ;

%%
% Create the Kriging metamodel:
myKriging = uq_createModel(MetaOpts);

%%
% Print the Kriging model
uq_print(myKriging) ;

%%
% Display the Kriging model
uq_display(myKriging) ;

%% 6 - TRAJECTORIES
%
% Specify a sampling mesh
Xval = linspace(0,15,200)';

%%
% Sample 10,000 trajectories of the Gaussian process
Ytraj = uq_evalModel(myKriging, Xval, 10000);

%%
% Estimate the mean and variance on the sampled trajectories
YmeanEst = mean(Ytraj,3);
YvarEst = var(Ytraj,0,3);

%%
% Plot ten trajectories and show the experimental design samples
uq_figure ;
uq_plot(Xval,squeeze(Ytraj(:,:,1:10))); hold on;
plot(X,Y,'ok','markerfacecolor','k','markersize',10);
xlabel('$X$')
ylabel('$Y$')

%% 
% Get the usual Kriging predictors (mean and variance)
[Ymean,Yvar] = uq_evalModel(myKriging,Xval);

%%
% Compare the empirical mean and the predicted mean 
uq_figure
uq_plot(Xval,Ymean) ; hold on
uq_plot(Xval,YmeanEst,'--')
xlabel('$x$')
ylabel('$\mu(x)$')
legend('Kriging mean','Empirical mean')
%%
% Compare the empirical variance and the predicted variance 
uq_figure
uq_plot(Xval,Yvar) ; hold on
uq_plot(Xval,YvarEst,'--')
xlabel('$x$')
ylabel('$\sigma^2(x)$');
legend('Kriging variance','Empirical variance')