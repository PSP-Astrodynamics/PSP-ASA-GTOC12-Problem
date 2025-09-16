%% STOCHASTIC POLYNOMIAL CHAOS EXPANSIONS - HESTON MODEL
%
% This example showcases how to build a stochastic polynomial chaos expansion (SPCE)
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
% Create an INPUT object based on the marginals:
myInput = uq_createInput(InputOpt);

%% 4 - STOCHASTIC POLYNOMIAL CHAOS EXPANSION (SPCE)
%% 4.1 Build SPCE with quadrature
%
% Select the metamodeling tool and the SPCE module:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'SPCE';

% Define the degrees
MetaOpts.Degree = 1:3;

% Specify the type of the latent variable
MetaOpts.Latent.Type = 'Gaussian';

% Specifiy the integration method for fitting
MetaOpts.IntMethod = 'Quadrature';
MetaOpts.Quadrature.Level = 50;% by default 100

% Specify the integration method for sigma selection
MetaOpts.Sigma.IntMethod = 'Quadrature';
% we use a different number of integration points to increase efficiency
MetaOpts.Sigma.Quadrature.Level = 200;% by default 1000

% Use an experimental design of size 1000
MetaOpts.ExpDesign.NSamples = 1000;

% Create the SPCE
mySPCEQUAD = uq_createModel(MetaOpts);

%% 4.2 Build SPCE with sampling-based integration
clear MetaOpts

MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'SPCE';

% Define the degrees
MetaOpts.Degree = 1:3;

% Specifiy the integration method for fitting
MetaOpts.IntMethod = 'Sampling';
MetaOpts.Sampling.N = 50;% by default 1000
MetaOpts.Sampling.Method = 'LHS';

% Specify the integration method for sigma selection
MetaOpts.Sigma.IntMethod = 'Sampling';
% we use a different number of integration points to increase efficiency
MetaOpts.Sigma.Sampling.N = 200;% by default 2000
MetaOpts.Sigma.Sampling.Method = 'LHS';

% Use the ED from the previous fit
MetaOpts.ExpDesign.X = mySPCEQUAD.ExpDesign.X;
MetaOpts.ExpDesign.Y = mySPCEQUAD.ExpDesign.Y;

% Create the SPCE
mySPCESAMPLE = uq_createModel(MetaOpts);

%% 4.3 Build SPCE using Matlab's builtin integrator

clear MetaOpts

MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'SPCE';

% Define the degrees
MetaOpts.Degree = 1:3;

% Specifiy the integration method for fitting
% We could choose 'MatlabInt' but this would slow down the computation
% drasmatically
MetaOpts.IntMethod = 'Quadrature';
MetaOpts.Quadrature.Level = 50;

% Specify the integration method for sigma selection
MetaOpts.Sigma.IntMethod = 'MatlabInt';

% Use the ED from the previous fit
MetaOpts.ExpDesign.X = mySPCEQUAD.ExpDesign.X;
MetaOpts.ExpDesign.Y = mySPCEQUAD.ExpDesign.Y;

% Create the SPCE
mySPCEMatlabInt = uq_createModel(MetaOpts);

%% 5 - VISUAL COMPARISION

% Define the points to visualize the associated PDFs
X4plot = uq_getSample(myInput,4,'LHS');

% Compute reference histograms
R = 1e3;
Y4plot = uq_evalModel(myModel,X4plot,R);

% Generate samples from the surrogates
Y4plotSPCEQUAD = uq_evalModel(mySPCEQUAD,X4plot,R);
Y4plotSPCESAMPLE = uq_evalModel(mySPCESAMPLE,X4plot,R);
Y4plotSPCEMatlabInt = uq_evalModel(mySPCEMatlabInt,X4plot,R);


for ix = 1:size(X4plot,1)
    uq_figure()
    uq_histogram(squeeze(Y4plot(ix,1,:)),'normalized','pdf');    
    hold on
    uq_histogram(squeeze(Y4plotSPCEQUAD(ix,1,:)),'normalized','pdf','FaceAlpha',0.5);    
    uq_histogram(squeeze(Y4plotSPCESAMPLE(ix,1,:)),'normalized','pdf','FaceAlpha',0.5);
    uq_histogram(squeeze(Y4plotSPCESAMPLE(ix,1,:)),'normalized','pdf','FaceAlpha',0.5);
    hold off
    xlim([0,max(Y4plot(ix,1,:))]);
    uq_legend({'Reference','Quadrature','LHS Sampling','Matlab integral'});
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

valMetricsQUAD = uq_SPCE_evalModelSampleMetrics(mySPCEQUAD,Xval,Yval);
fprintf('The validation normalized Wasserstein distance of the SPCE using quadrature is %1.3e. \n',valMetricsQUAD.NormalizedWSD);
valMetricsSAMPLE = uq_SPCE_evalModelSampleMetrics(mySPCESAMPLE,Xval,Yval);
fprintf('The validation normalized Wasserstein distance of the SPCE using LHS sampling is %1.3e. \n',valMetricsSAMPLE.NormalizedWSD);
valMetricsMatlabInt = uq_SPCE_evalModelSampleMetrics(mySPCEMatlabInt,Xval,Yval);
fprintf('The validation normalized Wasserstein distance of the SPCE using Matlab builtin integrator %1.3e. \n',valMetricsMatlabInt.NormalizedWSD);
