%% LRA METAMODELING: DEMONSTRATION OF BASIC USAGE
%
% This example showcases an application of a canonical 
% low-rank approximation (LRA) to the metamodeling 
% of a simply supported beam model that computes the mid-span deflection
% of the beam subjected to a uniform load.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL
%
% The simply supported beam model is shown in the following figure:
[I,~] = imread('SimplySupportedBeam.png');
uq_figure
image(I)
axis equal
set(gca, 'visible', 'off')

%%
% The midspan deflection of the beam is given by:
%
% $$ V = \frac{5}{32} \frac{pL^4}{E b h^3} $$
%
% This computation is carried out by the function
% |uq_SimplySupportedBeam(X)| supplied with UQLab.
% The function evaluates the input parameters gathered in the $N \times M$
% matrix |X|, where $N$ and $M$ are the numbers of realizations
% and inputs variables, respectively.
% The input variables are given in the following order:
%
% # $b$: beam width $(m)$
% # $h$: beam height $(m)$
% # $L$: beam length $(m)$
% # $E$: Young's modulus $(Pa)$
% # $p$: uniform load $(N/m)$

%%
% Create a MODEL object from the |uq_SimplySupportedBeam| function:
ModelOpts.mFile = 'uq_SimplySupportedBeam';

myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The simply supported beam model has five input variables,
% modeled by independent lognormal random variables.
% The detailed model is given in the following table:

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
% <td>Beam length</td>
% <td>Lognormal</td>
% <td>5 m</td>
% <td>50 mm</td>
% </tr>
% <tr>
% <td>E</td>
% <td>Young modulus</td>
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
% Specify these marginals and create a UQLab INPUT object:
InputOpts.Marginals(1).Name = 'b';  % beam width
InputOpts.Marginals(1).Type = 'Lognormal';
InputOpts.Marginals(1).Moments = [0.15 0.0075];   % (m)

InputOpts.Marginals(2).Name = 'h';  % beam height
InputOpts.Marginals(2).Type = 'Lognormal';
InputOpts.Marginals(2).Moments = [0.3 0.015];  % (m)

InputOpts.Marginals(3).Name = 'L';  % beam length
InputOpts.Marginals(3).Type = 'Lognormal';
InputOpts.Marginals(3).Moments = [5 0.05];  % (m)

InputOpts.Marginals(4).Name = 'E';  % Young's modulus
InputOpts.Marginals(4).Type = 'Lognormal';
InputOpts.Marginals(4).Moments = [3e10 4.5e9];  % (Pa)

InputOpts.Marginals(5).Name = 'p';  % uniform load
InputOpts.Marginals(5).Type = 'Lognormal';
InputOpts.Marginals(5).Moments = [1e4 2e3];  % (N/m)

myInput = uq_createInput(InputOpts);

%% 4 - LOW-RANK APPROXIMATION (LRA) METAMODEL
%
% Select the metamodeling tool and the LRA module:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'LRA';

%%
% Specify the range for the rank selection:
MetaOpts.Rank = 1:10;

%%
% Specify the range for the polynomial degree selection:
MetaOpts.Degree = 1:10;

%% 
% Configure UQLab to generate an experimental design of size $100$
% based on the latin hypercube sampling
% (also available: 'MC', 'Sobol', 'Halton'):
MetaOpts.ExpDesign.NSamples = 100;
MetaOpts.ExpDesign.Sampling = 'LHS';

%%
% Create the LRA metamodel:
myLRA = uq_createModel(MetaOpts);

%%
% Retrieve some useful results:
R = myLRA.LRA.Basis.Rank;  % optimal rank
errCV = myLRA.Error.SelectedCVScore;  % 3-fold cross-validation error

%%
% Print some basic information about the LRA metamodel:
uq_print(myLRA)

%%
% Plot the log absolute value of the equivalent PCE coefficients:
uq_display(myLRA)

%% 5 - VALIDATION
%
% Create a validation set:
Nval = 1e5;
Xval = uq_getSample(Nval);
Yval = uq_evalModel(myModel,Xval);

%%
% Evaluate the metamodel at the validation set:
YLRA = uq_evalModel(myLRA,Xval);

%%
% Compute the relative generalization error:
errG = sum((Yval-YLRA).^2)/Nval/var(Yval);

%%
% Plot the metamodel predictions vs. the actual responses
% at the validation set:
uq_figure

uq_plot(Yval, YLRA, '+')
hold on
uq_plot([min(Yval) max(Yval)], [min(Yval) max(Yval)], 'k')
hold off

axis equal tight
xlim([min(Yval) max(Yval)])
ylim([min(Yval) max(Yval)])

xlabel('$\mathrm{Y}$')
ylabel('$\mathrm{\widehat{Y}^{\rm LRA}}$')
title(['R = ', num2str(R), ', ',...
    '$\mathrm{\widehat{err}_G}$ = ', num2str(errG), ', ',...
    '$\mathrm{err_{\rm CV}}$ = ', num2str(errCV)])
