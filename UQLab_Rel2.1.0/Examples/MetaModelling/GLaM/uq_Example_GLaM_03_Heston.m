%% GENERALIZED LAMBDA METAMODELING - HESTON MODEL
%
% This example showcases how to build a generalized lambda model (GLaM)
% to represent the distribution of the end time value of a Heston model

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars;
uqlab;
rng(100,'twister')

%% 2 - COMPUTATIONAL MODEL
%
% The stochastic Heston model is implemented in the UQLab function
% |uq_Heston(X)|. The function evaluates the inputs gathered in 
% the $N \times M$ matrix |X|, where $N$ and $M$ are the numbers of realizations 
% and input variables, respectively.
% 
% Create a MODEL object from the |uq_Heston| function:
ModelOpts.mFile = 'uq_Heston';
ModelOpts.isStochastic = true;% the model is stochastic
ModelOpts.isVectorized = true;% the model is vectorized
myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of
% six independent uniform random variables

InputOpt.Marginals(1).Name = 'mu'; % Expected return rate
InputOpt.Marginals(1).Type = 'Uniform';
InputOpt.Marginals(1).Parameters = [0, 0.1];
InputOpt.Marginals(2).Name = 'kappa'; % Mean reversion speed of the volatility
InputOpt.Marginals(2).Type = 'Uniform';
InputOpt.Marginals(2).Parameters = [0.3, 2];
InputOpt.Marginals(3).Name = 'theta'; % Long term mean of the volatility
InputOpt.Marginals(3).Type = 'Uniform';
InputOpt.Marginals(3).Parameters = [0.02, 0.07];
InputOpt.Marginals(4).Name = 'sigma'; % Expected return rate
InputOpt.Marginals(4).Type = 'Uniform';
InputOpt.Marginals(4).Parameters = [0.2, 0.4];
InputOpt.Marginals(5).Name = 'rho'; % Mean reversion speed of the volatility
InputOpt.Marginals(5).Type = 'Uniform';
InputOpt.Marginals(5).Parameters = [-1, -0.5];
InputOpt.Marginals(6).Name = 'v0'; % Long term mean of the volatility
InputOpt.Marginals(6).Type = 'Uniform';
InputOpt.Marginals(6).Parameters = [0.02, 0.07];

% Create an INPUT object:
myInput = uq_createInput(InputOpt);

%% 4.1 - BUILD THE GENERALIZED LAMBDA METAMODEL
%
% Select the metamodeling tool and the GLaM module:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'GLaM';

%%
% Specify the range for the univariate polynomials 
% degree selection and truncation schemes
% for $\lambda_1-\lambda_4$
MetaOpts.Lambda(1).Degree=0:5;
MetaOpts.Lambda(1).TruncOptions.qNorm=0.2:0.2:0.8;
MetaOpts.Lambda(2).Degree=0:3;
MetaOpts.Lambda(2).TruncOptions.qNorm=0.2:0.2:0.8;
MetaOpts.Lambda(3).Degree=0:2;
MetaOpts.Lambda(3).TruncOptions.qNorm=0.2:0.2:0.8;
MetaOpts.Lambda(4).Degree=0:2;
MetaOpts.Lambda(4).TruncOptions.qNorm=0.2:0.2:0.8;

% Use an experimental design of size 2500, without replications
MetaOpts.ExpDesign.NSamples = 2500;

% Create the GLaM (by default the model selection criterion is BIC):
myGLaM_BIC = uq_createModel(MetaOpts);

%% 4.2 - BUILD THE GENERALIZED LAMBDA METAMODEL USING AIC AS MODEL SELECTION CRITERION

% Set the model selection criterion to AIC
MetaOpts.FullReg.SelectCrit = 'AIC';

% Use the same training set as the previous algorithm
MetaOpts.ExpDesign =struct;
MetaOpts.ExpDesign.X = myGLaM_BIC.ExpDesign.X;
MetaOpts.ExpDesign.Y = myGLaM_BIC.ExpDesign.Y;

myGLaM_AIC = uq_createModel(MetaOpts);

%% 5 - VISUAL COMPARISION

% Define the points to visualize the associated PDFs
X4plot = uq_getSample(myInput,4,'LHS');

% Compute reference histograms
R = 1e3;
Y4plot = uq_evalModel(myModel,X4plot,R);

% Evaluate the PDFs for the GLaM selected by BIC
lambdaBIC = uq_GLaM_evalLambda(myGLaM_BIC,X4plot);
[yplotBIC,xplotBIC]=uq_GLD_DistributionFunc(lambdaBIC,'pdf');

% Evaluate the PDFs for the GLaM selected by BIC
lambdaAIC = uq_GLaM_evalLambda(myGLaM_AIC,X4plot);
[yplotAIC,xplotAIC]=uq_GLD_DistributionFunc(lambdaAIC,'pdf');

for ix = 1:size(X4plot,1)
    uq_figure()
    uq_histogram(squeeze(Y4plot(ix,1,:)),'normalized','pdf');    
    hold on
    uq_plot(xplotBIC(ix,:), yplotBIC(ix,:));
    uq_plot(xplotAIC(ix,:), yplotAIC(ix,:));
    hold off
    xlim([0,max(Y4plot(ix,1,:))]);
    uq_legend({'Reference','BIC','AIC'});
    title(sprintf('PDF at point [%1.2f,%1.2f,%1.2f,%1.2f,%1.2f,%1.2f]',X4plot(ix,:)),...
        'FontSize', 16,...
        'Interpreter', 'LaTeX');
    xlabel('Y','Interpreter','Latex')
end

%% 6 - VALIDATION

% Create a validation set:
Nval = 200;
Xval = uq_getSample(myInput,Nval,'LHS');
Yval = uq_evalModel(myModel,Xval,500);% use 500 replications to represent the response distribution

valMetricsBIC = uq_GLaM_evalModelSampleMetrics(myGLaM_BIC,Xval,Yval);
fprintf('The validation normalized Wasserstein distance of the GLaM selected by BIC is %1.3e. \n',valMetricsBIC.NormalizedWSD);
valMetricsAIC = uq_GLaM_evalModelSampleMetrics(myGLaM_AIC,Xval,Yval);
fprintf('The validation normalized Wasserstein distance of the GLaM selected by AIC is %1.3e. \n',valMetricsAIC.NormalizedWSD);