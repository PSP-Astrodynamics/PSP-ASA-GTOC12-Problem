%% SENSITIVITY: COMPARISON OF MC- VS. PCE- AND LRA-BASED SOBOL' INDICES
%
% In this example, Sobol' sensitivity indices for the 
% <https://uqworld.org/t/borehole-function/ borehole function>
% are calculated with three different methods:
% Monte Carlo (MC) simulation, polynomial chaos expansion (PCE), 
% and canonical low-rank approximation (LRA).

%% 1 - INITIALIZE UQLAB
%
% Clear variables from the workspace,
% set random number generator for reproducible results,
% and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL
%
% The computational model is an $8$-dimensional analytical formula 
% that is used to model the water flow through a borehole.
% The borehole function |uq_borehole| is supplied with UQLab.
%
% Create a MODEL object from the function file:
ModelOpts.mFile = 'uq_borehole';

myModel = uq_createModel(ModelOpts);

%%
% Type |help uq_borehole| for information on the model structure as well as
% the description of each variable.

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of eight independent random 
% variables.
%
% Specify the marginals as follows:
InputOpts.Marginals(1).Name = 'rw';  % Radius of the borehole
InputOpts.Marginals(1).Type = 'Gaussian';
InputOpts.Marginals(1).Parameters = [0.10 0.0161812];  % (m)

InputOpts.Marginals(2).Name = 'r';  % Radius of influence
InputOpts.Marginals(2).Type = 'Lognormal';
InputOpts.Marginals(2).Parameters = [7.71 1.0056];  % (m)

InputOpts.Marginals(3).Name = 'Tu';  % Transmissivity, upper aquifer
InputOpts.Marginals(3).Type = 'Uniform';
InputOpts.Marginals(3).Parameters = [63070 115600];  % (m^2/yr)

InputOpts.Marginals(4).Name = 'Hu';  % Potentiometric head, upper aquifer
InputOpts.Marginals(4).Type = 'Uniform';
InputOpts.Marginals(4).Parameters = [990 1110];  % (m)

InputOpts.Marginals(5).Name = 'Tl';  % Transmissivity, lower aquifer
InputOpts.Marginals(5).Type = 'Uniform';
InputOpts.Marginals(5).Parameters = [63.1 116];  % (m^2/yr)

InputOpts.Marginals(6).Name = 'Hl';  % Potentiometric head , lower aquifer
InputOpts.Marginals(6).Type = 'Uniform';
InputOpts.Marginals(6).Parameters = [700 820];  % (m)

InputOpts.Marginals(7).Name = 'L';  % Length of the borehole
InputOpts.Marginals(7).Type = 'Uniform';
InputOpts.Marginals(7).Parameters = [1120 1680];  % (m)

InputOpts.Marginals(8).Name = 'Kw';  % Borehole hydraulic conductivity
InputOpts.Marginals(8).Type = 'Uniform';
InputOpts.Marginals(8).Parameters = [9855 12045];  % (m/yr)

%%
% Create an INPUT object based on the specified marginals:
myInput = uq_createInput(InputOpts);

%% 4 - SENSITIVITY ANALYSIS
%
% Sobol' indices are calculated first with a direct MC simulation 
% of the model and subsequently through post-processing of the
% coefficients of its PCE and LRA approximation.

%% 4.1 MC-based Sobol' indices
%
% Select the sensitivity analysis module in UQLab
% and the Sobol' analysis method:
SobolOpts.Type = 'Sensitivity';
SobolOpts.Method = 'Sobol';

%%
% Specify the maximum order of the Sobol' indices to be calculated:
SobolOpts.Sobol.Order = 1;

%%
% Specify the sample size for the MC simulation:
SobolOpts.Sobol.SampleSize = 1e5;
%%
% Note that the total cost of computation is $(M+2) \times N$,
% where $M$ is the input dimension and $N$ is the sample size.
% Therefore, the total cost for the current setup is
% $(8+2) \times 10^5 = 10^6$ evaluations of the full computational model.

%%
% Run the sensitivity analysis:
mySobolAnalysisMC = uq_createAnalysis(SobolOpts);

%%
% Retrieve the analysis results for comparison:
mySobolResultsMC = mySobolAnalysisMC.Results;

%% 4.2 PCE-based Sobol' indices
%
% Select the metamodeling tool in UQLab
% and the polynomial chaos expansion (PCE) type:
PCEOpts.Type = 'Metamodel';
PCEOpts.MetaType = 'PCE';

%%
% Assign the full computational model:
PCEOpts.FullModel = myModel;
%%
% The full model is used to generate an experimental design for the PCE. 

%%
% Specify the maximum polynomial degree (*default*: sparse PCE):
PCEOpts.Degree = 5;

%%
% Specify the size of the experimental design
% (i.e., the total computational cost of constructing the metamodel):
PCEOpts.ExpDesign.NSamples = 200;

%%
% Calculate the PCE:
myPCE = uq_createModel(PCEOpts);

%%
% The same options structure |SobolOpts| can be re-used
% to create a new analysis on the PCE model:
mySobolAnalysisPCE = uq_createAnalysis(SobolOpts);

%%
% Retrieve the results for comparison:
mySobolResultsPCE = mySobolAnalysisPCE.Results;

%%
% *Note*:
% The PCE metamodel does not need to be explicitly specified as
% the last created model will be used in the analysis.
% The sensitivity analysis module in UQLab recognizes PCE models and 
% calculates the Sobol' indices accordingly by post-processing the
% coefficients of a PCE model without sampling.

%% 4.3 LRA-based Sobol' indices
%
% Select the metamodeling tool in UQLab
% and the canonical low-rank approximation (LRA) type:
LRAOpts.Type = 'Metamodel';
LRAOpts.MetaType = 'LRA';

%%
% Assign the full computational model:
LRAOpts.FullModel = myModel;

%%
% Specify the rank range:
LRAOpts.Rank = 1:20;

%%
% Specify the degree range:
LRAOpts.Degree = 1:20;

%%
% Specify the size of the experimental design
% (i.e., the total computation cost of the metamodel):
LRAOpts.ExpDesign.NSamples = 200;

%% 
% Calculate the LRA:
myLRA = uq_createModel(LRAOpts);

%%
% As before, the same options structure |SobolOpts| can be re-used
% to create a new analysis on the LRA model:
mySobolAnalysisLRA = uq_createAnalysis(SobolOpts);

%%
% Retrieve the results for comparison:
mySobolResultsLRA = mySobolAnalysisLRA.Results;

%%
% *Note*:
% The LRA metamodel does not need to be explicitly specified as
% the last created model will be used in the analysis.
% The sensitivity analysis module in UQLab recognizes LRA models and 
% calculates the Sobol' indices accordingly by post-processing the
% coefficients of a LRA model without sampling.

%% 5 - COMPARISON OF THE RESULTS
%
% Print the results of the Sobol' indices calculation
% based on the MC simulation:
uq_print(mySobolAnalysisMC)

%%
% Print the results of the Sobol' indices calculation based on PCE:
uq_print(mySobolAnalysisPCE)

%%
% Print the results of the Sobol' indices calculation based on LRA:
uq_print(mySobolAnalysisLRA)

%%
% Compile the relevant results for comparison:
SobolTotal = [...
    mySobolResultsMC.Total ...
    mySobolResultsPCE.Total ...
    mySobolResultsLRA.Total];
SobolFirstOrder = [...
    mySobolResultsMC.FirstOrder ...
    mySobolResultsPCE.FirstOrder ...
    mySobolResultsLRA.FirstOrder];

%% 
% Create a bar plot to compare the total Sobol' indices:

% Create the plot
uq_figure('Name', 'Total Sobol'' Indices')
barWidth = 1;
uq_bar(1:8, SobolTotal, barWidth)
% Set axes limits
ylim([0 1])
xlim([0 9])
% Set labels
xlabel('Variable name')
ylabel('Total Sobol'' indices')
set(...
    gca,...
    'XTick', 1:length(InputOpts.Marginals),...
    'XTickLabel', mySobolResultsPCE.VariableNames)
% Set legend
uq_legend({...
    sprintf('MC-based (%.0e simulations)', mySobolResultsMC.Cost),...
    sprintf('PCE-based (%d simulations)', myPCE.ExpDesign.NSamples),...
    sprintf('LRA-based (%d simulations)', myLRA.ExpDesign.NSamples)},...
    'Location', 'northeast')

%% 
% Create a bar plot to compare the first-order Sobol' indices:

% Create the plot
uq_figure('Name', 'First-order Sobol'' Indices')
uq_bar(1:8, SobolFirstOrder, barWidth)
% Set axes limits
xlim([0 9])
ylim([0 1])
% Set labels
xlabel('Variable name')
ylabel('First-order Sobol'' indices')
set(...
    gca,...
    'XTick', 1:length(InputOpts.Marginals),...
    'XTickLabel', mySobolResultsPCE.VariableNames)
% Set legend
uq_legend({...
    sprintf('MC-based (%.0e simulations)', mySobolResultsMC.Cost),...
    sprintf('PCE-based (%d simulations)', myPCE.ExpDesign.NSamples),...
    sprintf('LRA-based (%d simulations)', myLRA.ExpDesign.NSamples)},...
    'Location', 'northeast')
