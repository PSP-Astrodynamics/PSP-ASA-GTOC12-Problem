%% SENSITIVITY: MULTIPLE OUTPUTS
%
% This example showcases an application of sensitivity analysis
% to a simply supported beam model.
% The model computes the deflections at several points along the length 
% of the beam subjected to a uniform random load.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100, 'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL
%
% The simply supported beam problem is shown in the following figure:
uq_figure
[I,~] = imread('SimplySupportedBeam.png');
image(I)
axis equal
set(gca,'visible','off')

%% 
% The (negative) deflection of the beam at any longitudinal coordinate
% $s$ is given by:
%
% $$V(s) = -\frac{p \,s (L^3 - 2\, s^2 L + s^3) }{2E b h^3}$$
%
% This computation is carried out by the function
% |uq_SimplySupportedBeam9Points(X)| supplied with UQLab.
% The function evaluates the inputs gathered in the $N \times M$
% matrix |X|, where $N$ and $M$ are the numbers of realizations and inputs,
% respectively.
% The inputs are given in the following order:
%
% # $b$: beam width $(m)$
% # $h$: beam height $(m)$
% # $L$: beam length $(m)$
% # $E$: Young's modulus $(Pa)$
% # $p$: uniform load $(N/m)$
%
% The function returns the beam deflection $V(s_i)$
% at nine equally-spaced points along the length
% $s_i = i \cdot L/10, \; i=1,\ldots,9.$ 
%
% Create a MODEL object from the function file:
ModelOpts.mFile = 'uq_SimplySupportedBeam9points';

myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL 
%
% The simply supported beam model has five input parameters
% modeled by independent lognormal random variables.
% The distributions of the random variables are given
% in the following table:

%%
% <html>
% <table border=1><tr>
% <td><b>Variable</b></td>
% <td><b>Description</b></td>
% <td><b>Distribution</b></td>
% <td><b>Mean</b></td>
% <td><b>Std. deviation</b></td></tr>
% <tr>
% <td>b</td>
% <td>Beam width</td>
% <td>Lognormal</td>
% <td>0.15 m</td>
% <td>7.5 mm</td>
% </tr>
% <tr>
% <td>h</td>
% <td>Beam height</td>
% <td>Lognormal</td>
% <td>0.3 m</td>
% <td>15 mm</td>
% </tr>
% <tr>
% <td>L</td>
% <td>Length</td>
% <td>Lognormal</td>
% <td>5 m</td>
% <td>50 mm</td>
% </tr>
% <tr>
% <td>E</td>
% <td>Young's modulus</td>
% <td>Lognormal</td>
% <td>30000 MPa</td>
% <td>4500 MPa</td>
% </tr>
% <tr>
% <td>p</td>
% <td>Uniform load</td>
% <td>Lognormal</td>
% <td>10 kN/m</td>
% <td>2 kN/m</td>
% </tr>
% </table>
% </html>

%%
% Specify the marginals as follows:
InputOpts.Marginals(1).Name = 'b';  % beam width
InputOpts.Marginals(1).Type = 'Lognormal';
InputOpts.Marginals(1).Moments = [0.15 0.0075];  % (m)

InputOpts.Marginals(2).Name = 'h';  % beam height
InputOpts.Marginals(2).Type = 'Lognormal';
InputOpts.Marginals(2).Moments = [0.3 0.015];  % (m)

InputOpts.Marginals(3).Name = 'L';  % beam length
InputOpts.Marginals(3).Type = 'Lognormal';
InputOpts.Marginals(3).Moments = [5 0.05];  % (m)

InputOpts.Marginals(4).Name = 'E';  % Young's modulus
InputOpts.Marginals(4).Type = 'Lognormal';
InputOpts.Marginals(4).Moments = [3e10 4.5e9] ;  % (Pa)

InputOpts.Marginals(5).Name = 'p';  % uniform load
InputOpts.Marginals(5).Type = 'Lognormal';
InputOpts.Marginals(5).Moments = [1e4 2e3];  % (N/m)

%%
% Create an INPUT object based on the specified marginals:
myInput = uq_createInput(InputOpts);

%% 4 - SENSITIVITY ANALYSIS
%
% Sensitivity analysis is performed by calculating the Sobol' indices
% for each of the output components separately.

%%
% Select the Sobol' sensitivity tool:
SobolOpts.Type = 'Sensitivity';
SobolOpts.Method = 'Sobol';

%%
% Specify the sample size of each variable:
SobolOpts.Sobol.SampleSize = 1e4;
%%
% Note that the total cost of computation is $(M+2) \times N$,
% where $M$ is the input dimension and $N$ is the sample size.
% Therefore, the total cost for the current setup is
% $(5+2) \times 10^4 = 7 \times 10^4$ evaluations of the full computational
% model.

%%
% Run the sensitivity analysis:
mySobolAnalysis = uq_createAnalysis(SobolOpts);

%% 5 - RESULTS VISUALIZATION
%
% Print out a report of the results:
uq_print(mySobolAnalysis)

%%
% Retrieve the analysis results (the total and first-order indices):
SobolResults = mySobolAnalysis.Results;
TotalSobolIndices = SobolResults.Total;
FirstOrderIndices = SobolResults.FirstOrder;

%%
% Plot the total Sobol' indices for all the output components:
uq_bar(TotalSobolIndices)
% Set plot limits
ylim([0 1])
xlim([-1 6])
% Set title and labels
title('Total Sobol'' indices')
xlabel('Input variable')
ylabel('$\mathrm{S_i^T}$')
% Set axis ticks and legend
set(...
    gca,...
    'XTick', 1:length(SobolResults.VariableNames),...
    'XTickLabel', SobolResults.VariableNames)
yNames = {...
    '$\mathrm Y_1$', '$\mathrm Y_2$', '$\mathrm Y_3$',...
    '$\mathrm Y_4$', '$\mathrm Y_5$', '$\mathrm Y_6$',...
    '$\mathrm Y_7$', '$\mathrm Y_8$', '$\mathrm Y_9$'};
uq_legend(yNames, 'Location', 'northwest')

%%
% Plot the first-order Sobol' indices for all the output components:
uq_bar(FirstOrderIndices)
% Set plot limits
ylim([0 1])
xlim([-1 6])
% Set title and labels
title('First-order Sobol'' indices')
xlabel('Input variable')
ylabel('$\mathrm{S_i}$')
% Set axis ticks and legend
set(...
    gca,...
    'XTick', 1:length(SobolResults.VariableNames),...
    'XTickLabel', SobolResults.VariableNames)
uq_legend(yNames, 'Location', 'northwest')
