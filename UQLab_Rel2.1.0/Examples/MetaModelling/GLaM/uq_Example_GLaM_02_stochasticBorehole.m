%% GENERALIZED LAMBDA METAMODELING - STOCHASTIC BOREHOLE
%
% This example showcases how to build a generalized lambda model (GLaM)
% to represent the distribution of the end time value of a stochastic
% borehole model

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars;
uqlab;
rng(100,'twister')

%% 2 - COMPUTATIONAL MODEL
%
% The stochastic borehole function is implemented in the UQLab function
% |uq_borehole_stochastic(X)|. The function evaluates the inputs gathered in 
% the $N \times M$ matrix |X|, where $N$ and $M$ are the numbers of realizations 
% and input variables, respectively.

% Create a MODEL object from the function file:
ModelOpts.mFile = 'uq_borehole_stochastic';
ModelOpts.isStochastic = true;% the model is stochastic
ModelOpts.isVectorized = true;% the model is vectorized
ModelOpts.stochasticSim.supportRep = true;% the model supports replications
myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of
% three independent random variables:
%
% $X_1 \sim \mathcal{N}(0.1, 0.01618412)$
% $X_2 \sim \mathcal{U}(990, 1110)$
% $X_3 \sim \mathcal{U}(9855, 12045)$

InputOpt.Marginals(1).Name = 'rw'; % Radius of the borehole (m)
InputOpt.Marginals(1).Type = 'Gaussian';
InputOpt.Marginals(1).Parameters = [0.10, 0.0161812];
InputOpt.Marginals(2).Name = 'Hu'; % Potentiometric head of the upper aquifer (m)
InputOpt.Marginals(2).Type = 'Uniform';
InputOpt.Marginals(2).Parameters = [990, 1110];
InputOpt.Marginals(3).Name = 'Kw'; % Hydraulic conductivity of the borehole (m/yr)
InputOpt.Marginals(3).Type = 'Uniform';
InputOpt.Marginals(3).Parameters = [9855, 12045];

% Create an INPUT object based on the marginals:
myInput = uq_createInput(InputOpt);

%% 4.0 - SETUP THE OPTIONS FOR GLAM
%
% Select the metamodeling tool and the GLaM module:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'GLaM';

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

%% 4.1 - BUILD A GLAM WITH REPLICATIONS

% Specify the replication-based method
MetaOpts.Method = 'RepJoint';

% Configure UQLab to generate an experimental design of size 20
% based on the latin hypercube sampling
MetaOpts.ExpDesign.Sampling = 'LHS';
MetaOpts.ExpDesign.NSamples = 30;
% For the replication-based algorithm, we need to specify the number of
% replications. Here, it is set to 40
MetaOpts.ExpDesign.Replications = 25;

% Create the GLaM:
myGLaMRepJoint = uq_createModel(MetaOpts);
uq_print(myGLaMRepJoint)

%% 4.2 - BUILD A GLAM WITHOUT REPLICATIONS

% Specify the full regression method 
MetaOpts.Method = 'FullReg';

% Configure UQLab to generate an experimental design of size $800$
% based on the latin hypercube sampling:
MetaOpts.ExpDesign = struct;
MetaOpts.ExpDesign.NSamples = 750;

% Create the GLaM:
myGLaMFullReg = uq_createModel(MetaOpts);
uq_print(myGLaMFullReg)
%% 5 - VISUAL COMPARISION

% Define the points to visualize the associated PDFs
X4plot = [0.1,1050,10950
    0.08,1000,10000
    0.12,1100,11500
    0.14,1020,11800];

% Compute reference histograms
R = 1e5;
Y4plot = uq_evalModel(myModel,X4plot,R);

% Evaluate the PDFs for the GLaM built from the method RepJoint
lambdaFullReg = uq_GLaM_evalLambda(myGLaMFullReg,X4plot);
[yplotFullReg,xplotFullReg]=uq_GLD_DistributionFunc(lambdaFullReg,'pdf');

% Evaluate the PDFs for the GLaM built from the method RepJoint
lambdaRepJoint = uq_GLaM_evalLambda(myGLaMRepJoint,X4plot);
[yplotRepJoint,xplotRepJoint]=uq_GLD_DistributionFunc(lambdaRepJoint,'pdf');

for ix = 1:size(X4plot,1)
    uq_figure()
    uq_histogram(squeeze(Y4plot(ix,1,:)),'normalized','pdf');    
    hold on
    uq_plot(xplotRepJoint(ix,:), yplotRepJoint(ix,:));
    uq_plot(xplotFullReg(ix,:), yplotFullReg(ix,:));
    hold off
    uq_legend({'Reference','FullReg','RepJoint'});
    title(sprintf('PDF at point [%1.2f,%1.2f,%1.2f]',X4plot(ix,:)),...
        'FontSize', 16,...
        'Interpreter', 'LaTeX');
    xlabel('Y','Interpreter','Latex')
end

%% 6 - VALIDATION

% Create a validation set:
Nval = 1e3;
Xval = uq_getSample(myInput,Nval,'LHS');
Yval = uq_evalModel(myModel,Xval,1e4);% use 1e4 replications to represent the response distribution

% Evaluate some metrics of the metamodel at the validation set:
valMetricsFullReg = uq_GLaM_evalModelSampleMetrics(myGLaMFullReg,Xval,Yval);
fprintf('The validation normalized Wasserstein distance of the replication-based method is %1.3e. \n',valMetricsFullReg.NormalizedWSD);
valMetricsRepJoint = uq_GLaM_evalModelSampleMetrics(myGLaMRepJoint,Xval,Yval);
fprintf('The validation normalized Wasserstein distance of the replication-based method is %1.3e. \n',valMetricsRepJoint.NormalizedWSD);