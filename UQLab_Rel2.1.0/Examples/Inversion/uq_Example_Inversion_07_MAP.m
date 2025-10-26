%% INVERSION: MAXIMUM A POSTERIORI (MAP) ESTIMATION
%
% This example uses the Bayesian inversion module to set up an inverse
% problem without perorming any MCMC sampling of the posterior
% distribution. 
% Instead, the maximum a posteriori (MAP) estimates of the model parameters
% are computed from the unnormalized posterior probability 
% density function that is provided by the module.
% The problem setup is a linear regression model similar 
% to the one in uq_Example_Inversion_02_LinearRegression.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%%
% Load the constant matrix $A$ of size $24 \times 8$ which defines
% the linear model $Y = AX$ (contained in a structure called |Model|)
% and the data |Data|:
load('uq_Example_BayesianLinearRegression')

%% 2 - FORWARD MODEL
%
% The linear model is defined by a regression matrix $\mathbf{A}$
% that maps an $8$-dimensional input parameter vector $\mathbf{x}$ $(M=8)$ 
% to a $24$-dimensional output vector $\tilde{\mathbf{y}}$ $(N_{out}=24)$:
%
% $$\tilde{\mathbf{y}} = \mathbf{A} \mathbf{x}$$
%
% Define the forward model as a UQLab MODEL object:
ModelOpts.mHandle = @(x) x * Model.A;
ModelOpts.isVectorized = true;

myForwardModel = uq_createModel(ModelOpts);

%% 3 - PRIOR DISTRIBUTION OF THE MODEL PARAMETERS
%
% A simple standard normal prior model is assumed on the input variables
%
% $$X_i \sim \mathcal{N}(0, 1)\quad i = 1,...,8$$
%
% Specify these distributions as a UQLab INPUT object:

for i = 1:Model.M
  PriorOpts.Marginals(i).Type = 'Gaussian';
  PriorOpts.Marginals(i).Parameters = [0 1];
end

myPriorDist = uq_createInput(PriorOpts);

%% 4 - MEASUREMENT DATA
%
% Provide the set of measurements that are stored in the 'Data' vector to
% the measurement vector |y|
myData.y = Data;

%% 5 - DISCREPANCY MODEL
%
% The problem is solved with an unknown residual variance 
% parameter $\sigma^2$ for all $N_{out} = 24$ residuals $\varepsilon_i$.
% To infer the error variance, a uniform prior is put on this
% discrepancy parameter:
%
% $$\sigma^2 \sim \mathcal{U}(0,20).$$
%
% Create this distribution as a UQLab INPUT object:
SigmaOpts.Name = 'Prior of sigma2';
SigmaOpts.Marginals(1).Name = 'Sigma2';
SigmaOpts.Marginals(1).Type = 'Uniform';
SigmaOpts.Marginals(1).Parameters = [0 20];

mySigmaDist = uq_createInput(SigmaOpts);

%%
% Assign the distribution of $\sigma^2$ to the discrepancy options:
DiscrepancyOpts.Type = 'Gaussian';
DiscrepancyOpts.Prior = mySigmaDist;

%% 6 - SOLVER OPTIONS
%
% In this example, the Bayesian inversion module is only used to create
% function handles to the prior, likelihood and unnormalized posterior
% functions. 
% Therefore, the Solver type is set to |'none'|:
Solver.Type = 'none';

%% 7 - BAYESIAN ANALYSIS OBJECT
%
% The options are gathered in a single structure
BayesOpts.Type = 'Inversion';
BayesOpts.Name = 'Bayesian model, initialize only';
BayesOpts.Data = myData;
BayesOpts.Discrepancy = DiscrepancyOpts;
BayesOpts.Prior = myPriorDist;
BayesOpts.Solver = Solver;

%%
% And used to create an ANALYSIS object within UQLab
myBayesianAnalysis = uq_createAnalysis(BayesOpts);

%%
% Print out a report of the problem setup:
uq_print(myBayesianAnalysis)

%% 8 - MAXIMUM A POSTERIORI (MAP) ESTIMATION
%
% Extract the handle to the negative unnormalized log-posterior
% distribution 
negPropPost = @(x) - myBayesianAnalysis.UnnormLogPosterior(x);

%%
% Extract the prior mean and standard deviation from the analysis object to
% initialize the MAP optimization
priorMoments = reshape(...
    [myBayesianAnalysis.Internal.FullPrior.Marginals.Moments],2,[]);
priorMean = priorMoments(1,:);
priorStd = priorMoments(2,:);

%%
% The minimum of the negative log posterior density is computed using the
% covariance matrix adaptation-evolution strategy (CMA-ES) optimization
% algorithm. First, define lower and upper bounds for the optimization
% algorithm:
lb = [-inf(1,8) 0];
ub = [inf(1,8) 20];

%%
% Then, minimize the negative unnormalized log-posterior to identify the
% posterior mode
MAP = uq_cmaes(negPropPost, priorMean, priorStd, lb, ub);

%%
% The resulting MAP parameters estimates contain both model and discrepancy
% parameters.  
% They can be split by:
modelMAP = MAP(1:Model.M);
discrepancyMAP = MAP(Model.M+1:end);

%%
% Evaluate the forward model on the MAP estimate to compare it with the
% experimental data
modelEvaluationMAP = uq_evalModel(myForwardModel,modelMAP);

%%
% Compare the data against the MAP predictions:
uq_figure
hh = uq_plot(...
    1:numel(Data), Data, 'o',...
    1:numel(Data), modelEvaluationMAP, 'x');
set(hh(2), 'MarkerSize', get(hh(1),'MarkerSize')+2)
hold off
ylim([-8 8])
xlim([1 24])
uq_legend({'Data', 'MAP Prediction'}, 'Location', 'southeast')
ylabel('$\mathrm{y}$')
xlabel('$\mathrm{Output\,index\,}$')