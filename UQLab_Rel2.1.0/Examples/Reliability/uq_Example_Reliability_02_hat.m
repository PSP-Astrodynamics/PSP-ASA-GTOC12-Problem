%% RELIABILITY: TWO-DIMENSIONAL HAT FUNCTION
%
% This example showcases the application of various reliability analysis
% methods in UQLab to a two-dimensional hat function.

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
% The two-dimensional hat function is defined as follows:
%
% $$g(x_1, x_2) = 20 - (x_1 - x_2)^2 - 8 (x_1 + x_2 - 4)^3$$
%
% Create a limit state function model based on the hat function
% using a string, written below in a vectorized operation:
ModelOpts.mString = '20 - (X(:,1)-X(:,2)).^2 - 8*(X(:,1)+X(:,2)-4).^3';
ModelOpts.isVectorized = true;

myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of two independent
% and identically-distributed Gaussian random variables:
%
% $X_i \sim \mathcal{N}(0.25, 1), \quad i = 1, 2$
%
% Specify the marginals of the two input random variables:
InputOpts.Marginals(1).Name = 'X1'; 
InputOpts.Marginals(1).Type = 'Gaussian';
InputOpts.Marginals(1).Parameters = [0.25 1];

InputOpts.Marginals(2).Name = 'X2';  
InputOpts.Marginals(2).Type = 'Gaussian';
InputOpts.Marginals(2).Parameters = [0.25 1];

%%
% Create an INPUT object based on the specified marginals:
myInput = uq_createInput(InputOpts);

%% 4 - STRUCTURAL RELIABILITY
%
% Failure event is defined as $g(\mathbf{x}) \leq 0$.
% The failure probability is then defined as
% $P_f = P[g(\mathbf{x})\leq 0]$.
%
% Reliability analysis is performed with the following methods:
%
% * Monte Carlo simulation (MCS)
% * Subset simulation
% * Adaptive-Kriging-Monte-Carlo-Simulation (AK-MCS)
% * Adaptive-Polynomial-Chaos-Kriging-Monte-Carlo-Simulation (APCK-MCS)
% * Stochastic spectral embedding-based reliability (SSER)
% * Line Sampling (LS)
% * Baysesian Line Sampling (BLS)

%% 4.1 Monte Carlo simulation (MCS)
%
% Select the Reliability module and the Monte Carlo simulation (MCS)
% method:
MCSOpts.Type = 'Reliability';
MCSOpts.Method = 'MCS';

%%
% Specify the maximum sample size, the size of the batch,
% and the target coefficient of variation:
MCSOpts.Simulation.MaxSampleSize = 1e6;
MCSOpts.Simulation.BatchSize = 1e5;
MCSOpts.Simulation.TargetCoV = 1e-2;

%%
% Run the Monte Carlo simulation:
myMCSAnalysis = uq_createAnalysis(MCSOpts);

%%
% Print out a report of the results:
uq_print(myMCSAnalysis)

%% 
% Visualize the results of the analysis:
uq_display(myMCSAnalysis)

%% 4.2 Subset simulation
%
% Select the Reliability module and the subset simulation method:
SubsetSimOpts.Type = 'Reliability';
SubsetSimOpts.Method = 'Subset';

%%
% Specify the sample size in each subset:
SubsetSimOpts.Simulation.BatchSize = 1e4;

%%
% Run the subset simulation analysis
mySubsetSimAnalysis = uq_createAnalysis(SubsetSimOpts);

%%
% Print out a report of the results:
uq_print(mySubsetSimAnalysis)

%%
% Visualize the results of the analysis:
uq_display(mySubsetSimAnalysis)

%% 4.3 Adaptive-Kriging-Monte-Carlo-Simulation (AK-MCS)
%
% Select the Reliability module and the AK-MCS method:
AKMCSOpts.Type = 'Reliability';
AKMCSOpts.Method = 'AKMCS';

%%
% Specify the size of the Monte Carlo sample set used for 
% the Monte Carlo simulation
% and as the candidate set for the learning function:
AKMCSOpts.Simulation.MaxSampleSize = 1e6;

%% 
% Specify the maximum number of sample points added
% to the experimental design:
AKMCSOpts.AKMCS.MaxAddedED = 20;

%%
% Specify the initial experimental design:
AKMCSOpts.AKMCS.IExpDesign.N = 20;
AKMCSOpts.AKMCS.IExpDesign.Sampling = 'LHS';

%%
% Specify the options for the Kriging metamodel
% (note that all Kriging options are supported):
AKMCSOpts.AKMCS.Kriging.Corr.Family = 'Gaussian';

%%
% Specify the convergence criterion
% for the adaptive experimental design algorithm
% (here, it is based on the failure probability estimate):
AKMCSOpts.AKMCS.Convergence = 'stopPf';

%%
% Specify the learning function
% (here, it is the _expected feasibility function (EFF)_):
AKMCSOpts.AKMCS.LearningFunction = 'EFF';

%%
% Run the AK-MCS analysis:
myAKMCSAnalysis = uq_createAnalysis(AKMCSOpts);

%%
% Print out a report of the results:
uq_print(myAKMCSAnalysis)

%%
% Visualize the results of the analysis:
uq_display(myAKMCSAnalysis)

%% 4.4 Adaptive-Polynomial-Chaos-Kriging-Monte-Carlo-Simulation (APCK-MCS)
%
% APCK-MCS is a variation of AK-MCS in which the Kriging model
% is replaced by a PC-Kriging (PCK) model.
%
% Select the Reliability module and the AK-MCS method:
APCKMCSOpts.Type = 'Reliability';
APCKMCSOpts.Method = 'AKMCS';

%%
% Select PCK as the metamodel type:
APCKMCSOpts.AKMCS.MetaModel = 'PCK';

%%
% Specify the correlation function for the Kriging metamodel 
% (here, it is the Gaussian correlation function):
APCKMCSOpts.AKMCS.PCK.Kriging.Corr.Family = 'Gaussian';

%% 
% Set the number of sample points in the initial experimental design:
APCKMCSOpts.AKMCS.IExpDesign.N = 5;

%%
% Specify the size of the Monte Carlo set used for
% the Monte Carlo simulation
% and as the candidate set for the learning function:
APCKMCSOpts.Simulation.MaxSampleSize = 1e6;

%%
% Run the APCK-MCS analysis:
myAPCKMCSAnalysis = uq_createAnalysis(APCKMCSOpts);

%%
% Print out a report of the results:
uq_print(myAPCKMCSAnalysis)

%% 
% Visualize the results of the analysis:
uq_display(myAPCKMCSAnalysis)

%% 4.5 Stochastic spectral embedding-based reliability (SSER)
%
% SSER is an active learning reliability method that constructs a
% stochastic spectral embedding of the limit state function with smart
% refinement, partitioning, and sample enrichment strategies.
%
% Select the Reliability module and the SSER method:
SSEROpts.Type = 'Reliability';
SSEROpts.Method = 'SSER';

%% 
% Set the number of samples to be added in every refinement domain:
SSEROpts.SSER.ExpDesign.NEnrich = 20;

%% 
% Select the polynomial degree of the residual expansion:
SSEROpts.SSER.ExpOptions.Degree = 0:3;

%%
% Run the SSER analysis:
mySSERAnalysis = uq_createAnalysis(SSEROpts);

%%
% Print out a report of the results:
uq_print(mySSERAnalysis)

%% 
% Visualize the results of the analysis:
uq_display(mySSERAnalysis)

%% 4.6 Line Sampling (LS)
%
% Select the Reliability module and the Line Sampling (LS) method:
LSOpts.Type = 'Reliability';
LSOpts.Method = 'LS';

%%
% Specify the maximum sample size, the size of the batch,
% and the target coefficient of variation:
LSOpts.LS.MaxLines = 1000;
LSOpts.LS.BatchSize = 100;
LSOpts.LS.TargetCoV = 0.05;

%%
% Run the Line Sampling simulation:
myLSAnalysis = uq_createAnalysis(LSOpts);

%%
% Print out a report of the results:
uq_print(myLSAnalysis)

%% 
% Visualize the results of the analysis:
uq_display(myLSAnalysis)

%% 4.7 Bayesian Line Sampling (BLS)
%
% Select the Reliability module and the Bayesian Line Sampling (BLS) 
% method:
BLSOpts.Type = 'Reliability';
BLSOpts.Method = 'BLS';

%%
% Specify the maximum sample size, the size of the batch,
% and the target coefficient of variation for the MC estimation of the
% moments:
BLSOpts.Simulation.MaxSampleSize = 1e6;
BLSOpts.Simulation.BatchSize = 1e5;
BLSOpts.Simulation.TargetCoV = 0.05;

%%
% Specify the learning function:
BLSOpts.BLS.LearningFunction = 'upper variance';

%%
% Set stopping CoV of the Bayesian active learning:
BLSOpts.BLS.ConvCoV = 0.1;

%%
% Specify the options of the Kriging model:
BLSOpts.BLS.Kriging.Trend.Type = 'linear';

%%
% Enable verbose display:
BLSOpts.Display = 5;

%%
% % Run the BAL-LS analysis
myBLSAnalysis = uq_createAnalysis(BLSOpts);

%%
% Print out a report of the results:
uq_print(myBLSAnalysis)

%%
% Create a graphical representation of the results:
uq_display(myBLSAnalysis)

