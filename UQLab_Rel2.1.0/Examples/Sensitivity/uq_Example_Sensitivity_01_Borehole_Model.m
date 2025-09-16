%% SENSITIVITY: BOREHOLE MODEL
%
% This example showcases the application of different sensitivity analysis
% techniques available in UQLab to the 
% <https://uqworld.org/t/borehole-function/ borehole function>.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
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
% Sensitivity analysis on the borehole model is performed
% with the following methods:
%
% * Input/output correlation
% * Standard Regression Coefficients
% * Perturbation method
% * Cotter sensitivity indices
% * Morris elementary effects
% * Sobol' sensitivity indices
% * Borgonovo sensitivity indices

%% 4.1 Input/output correlation analysis
%
% Select the sensitivity tool and the correlation method:
CorrSensOpts.Type = 'Sensitivity';
CorrSensOpts.Method = 'Correlation';

%%
% Specify the sample size used to calculate the correlation-based indices:
CorrSensOpts.Correlation.SampleSize = 1e4;

%%
% Run the sensitivity analysis:
CorrAnalysis = uq_createAnalysis(CorrSensOpts);

%%
% Print the results of the analysis:
uq_print(CorrAnalysis)

%%
% Display a graphical representation of the results:
uq_display(CorrAnalysis)

%% 4.2 Standard Regression Coefficients (SRC)
%
% Select the sensitivity tool and the SRC method:
SRCSensOpts.Type = 'Sensitivity';
SRCSensOpts.Method = 'SRC';

%%
% Specify the sample size used to calculate the regression-based indices:
SRCSensOpts.SRC.SampleSize = 1e4;

%%
% Run the sensitivity analysis:
SRCAnalysis = uq_createAnalysis(SRCSensOpts);

%%
% Print the results of the analysis:
uq_print(SRCAnalysis)

%%
% Display a graphical representation of the results:
uq_display(SRCAnalysis)

%% 4.3 Perturbation-based indices 
%
% Select the sensitivity tool and the perturbation method:
PerturbationSensOpts.Type = 'Sensitivity';
PerturbationSensOpts.Method = 'Perturbation';

%%
% Run the sensitivity analysis:
PerturbationAnalysis = uq_createAnalysis(PerturbationSensOpts);

%%
% Print the results of the analysis:
uq_print(PerturbationAnalysis)

%%
% Display a graphical representation of the results:
uq_display(PerturbationAnalysis)

%% 4.4 Cotter sensitivity indices
%
% Select the sensitivity tool and the Cotter method:
CotterSensOpts.Type = 'Sensitivity';
CotterSensOpts.Method = 'Cotter';

%%
% Specify the boundaries for the factorial design:
CotterSensOpts.Factors.Boundaries = 0.5;

%%
% Run the sensitivity analysis:
CotterAnalysis = uq_createAnalysis(CotterSensOpts);

%%
% Print the results of the analysis:
uq_print(CotterAnalysis)

%%
% Display a graphical representation of the results:
uq_display(CotterAnalysis)

%% 4.5 Morris' elementary effects
%
% Select the sensitivity tool and the Morris method:
MorrisSensOpts.Type = 'Sensitivity';
MorrisSensOpts.Method = 'Morris';

%%
% Specify the boundaries for the Morris method:
MorrisSensOpts.Factors.Boundaries = 0.5;
%%
% Make sure there are no unphysical values
% (e.g., with the positive-only lognormal variable #2).

%%
% Specify the maximum cost (in terms of model evaluations) to calculate
% the Morris elementary effects:
MorrisSensOpts.Morris.Cost = 1e4;

%%
% Run the sensitivity analysis:
MorrisAnalysis = uq_createAnalysis(MorrisSensOpts);

%%
% Print the results of the analysis:
uq_print(MorrisAnalysis)

%%
% Display a graphical representation of the results:
uq_display(MorrisAnalysis)

%% 4.6 Sobol' indices
%
% Select the sensitivity tool and the Sobol' method:
SobolOpts.Type = 'Sensitivity';
SobolOpts.Method = 'Sobol';

%%
% Specify the maximum order of the Sobol' indices calculation:
SobolOpts.Sobol.Order = 1;

%%
% Specify the sample size for the indices estimation of each variable
SobolOpts.Sobol.SampleSize = 1e4;
%%
% Note that the total cost of computation is $(M+2)\times N$,
% where $M$ is the input dimension and $N$ is the sample size.
% Therefore, the total cost for the current setup is
% $(8+2)\times 10^4 = 10^5$ evaluations of the full computational model.

%%
% Run the sensitivity analysis:
SobolAnalysis = uq_createAnalysis(SobolOpts);

%%
% Print the results of the analysis:
uq_print(SobolAnalysis)

%%
% Create a graphical representation of the results:
uq_display(SobolAnalysis)

%% 4.7 Borgonovo indices
%
% Select the sensitivity tool and the Borgonovo method:
BorgonovoOpts.Type = 'Sensitivity';
BorgonovoOpts.Method = 'Borgonovo';

%%
% Specify the sample size:
BorgonovoOpts.Borgonovo.SampleSize = 1e4;
%%
% A relatively large sample size is recommended for Borgonovo indices 
% estimation, especially for complex functions.

%%
% Specify the amount of classes in Xi direction:
BorgonovoOpts.Borgonovo.NClasses = 20;

%%
% By default, UQLab will then create classes that contain
% the same amount of sample points.

%%
% Run the sensitivity analysis:
BorgonovoAnalysis = uq_createAnalysis(BorgonovoOpts);

%%
% Print the results of the analysis:
uq_print(BorgonovoAnalysis)

%%
% Create a graphical representation of the results:
uq_display(BorgonovoAnalysis)

%%
% In order to assess the accuracy of the results, it is possible to inspect 
% the 2D histogram estimation of the joint distribution used in the 
% calculation of an index:
uq_display(BorgonovoAnalysis, 1, 'Joint PDF', 1)
