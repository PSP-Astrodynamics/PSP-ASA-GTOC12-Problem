%% RELIABILITY: RESISTANCE VS. STRESS (R-S)
%
% This example showcases the application of different reliability analysis
% methods available in UQLab to the simple R-S example.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL
%
% The R-S function is defined as:
%
% $$g(\mathbf{x}) = R - S$$
%
% where $\mathbf{x} = \{R,S\}$.
% $R$ and $S$ are the resistance and stress variables, respectively.
%
% Create a limit state function model using a string,
% written below in a vectorized operation:
ModelOpts.mString = 'X(:,1) - X(:,2)';
ModelOpts.isVectorized = true;

myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of two independent Gaussian 
% random variables:
%
% $$R \sim \mathcal{N}(5, 0.8), \; S \sim \mathcal{N}(2, 0.6)$$
%
% Specify the probabilistic input model for the $R$ and $S$ variables:
InputOpts.Marginals(1).Name = 'R';  % resistance variable
InputOpts.Marginals(1).Type = 'Gaussian';
InputOpts.Marginals(1).Moments = [5 0.8];

InputOpts.Marginals(2).Name = 'S';  % stress variable
InputOpts.Marginals(2).Type = 'Gaussian';
InputOpts.Marginals(2).Moments = [2 0.6];

%%
% Create an INPUT object based on the specified marginals:
myInput = uq_createInput(InputOpts);

%% 4 - RELIABILITY ANALYSIS
%
% Failure event is defined as $g(\mathbf{x}) \leq 0$.
% The failure probability is then defined
% as $P_f = P[g(\mathbf{x}) \leq 0]$.
%
% Reliability analysis is performed with the following methods:
%
% * Monte Carlo simulation
% * First-order reliability method (FORM)
% * Importance sampling (IS)
% * Subset simulation
% * Adaptive Kriging-Monte Carlo Simulation (AK-MCS)
% * Stochastic spectral embedding-based reliability (SSER)
% * Line Sampling (LS)
% * Bayesian Line Sampling (BLS)

%% 4.1 Monte Carlo simulation (MCS)
%
% Select the Reliability module and the Monte Carlo simulation (MCS)
% method:
MCSOpts.Type = 'Reliability';
MCSOpts.Method = 'MCS';

%%
% Specify the maximum sample size:
% MCSOpts.Simulation.MaxSampleSize = 1e6;

%%
% Run reliability analysis with MCS:
MCSAnalysis = uq_createAnalysis(MCSOpts);

%%
% Print out a report of the results:
uq_print(MCSAnalysis)

%%
% Create a graphical representation of the results:
uq_display(MCSAnalysis)

%% 4.2 FORM
%
% Select FORM as the reliability analysis method:
FORMOpts.Type = 'Reliability';
FORMOpts.Method = 'FORM';

%%
% Run the FORM analysis:
FORMAnalysis = uq_createAnalysis(FORMOpts);

%%
% Print out a report of the results:
uq_print(FORMAnalysis)

%%
% Create a graphical representation of the results:
uq_display(FORMAnalysis)

%% 4.3 Importance sampling (IS)
%
% Select importance sampling (IS) as the reliability analysis method:
ISOpts.Type = 'Reliability';
ISOpts.Method = 'IS';

%%
% Run the IS reliability analysis:
ISAnalysis = uq_createAnalysis(ISOpts);

%%
% Print out a report of the results:
uq_print(ISAnalysis)

%%
% Create a graphical representation of the results:
uq_display(ISAnalysis)

%% 4.4 Subset simulation
%
% Select subset simulation as the reliability analysis method:
SubsetSimOpts.Type = 'Reliability';
SubsetSimOpts.Method = 'Subset';

%%
% Run the subset simulation:
SubsetSimAnalysis = uq_createAnalysis(SubsetSimOpts);

%%
% Print out a report of the results:
uq_print(SubsetSimAnalysis)

%%
% Create a graphical representation of the results:
uq_display(SubsetSimAnalysis)

%% 4.5 Adaptive Kriging-Monte Carlo Simulation (AK-MCS)
%
% Select AK-MCS as the reliability analysis method:
AKMCSOpts.Type = 'Reliability';
AKMCSOpts.Method = 'AKMCS';

%%
% Run the AK-MCS analysis
AKMCSAnalysis = uq_createAnalysis(AKMCSOpts);

%%
% Print out a report of the results:
uq_print(AKMCSAnalysis)

%%
% Create a graphical representation of the results:
uq_display(AKMCSAnalysis)

%% 4.6 Stochastic spectral embedding-based reliability (SSER)
%
% Select SSER as the reliability analysis method:
SSEROpts.Type = 'Reliability';
SSEROpts.Method = 'SSER';

%%
% Run the SSER analysis
SSERAnalysis = uq_createAnalysis(SSEROpts);

%%
% Print out a report of the results:
uq_print(SSERAnalysis)

%%
% Create a graphical representation of the results:
uq_display(SSERAnalysis)

%% 4.7 Line Sampling (LS)
%
% Select LS as the reliability analysis method:
LSOpts.Type = 'Reliability';
LSOpts.Method = 'LS';

%%
% Run the LS analysis
LSAnalysis = uq_createAnalysis(LSOpts);

%%
% Print out a report of the results:
uq_print(LSAnalysis)

%%
% Create a graphical representation of the results:
uq_display(LSAnalysis)

%% 4.8 Bayesian Line Sampling (BLS)
%
% Select BLS as the reliability analysis method:
BLSOpts.Type = 'Reliability';
BLSOpts.Method = 'BLS';

%%
% Run the BLS analysis
BLSAnalysis = uq_createAnalysis(BLSOpts);

%%
% Print out a report of the results:
uq_print(BLSAnalysis)

%%
% Create a graphical representation of the results:
uq_display(BLSAnalysis)
