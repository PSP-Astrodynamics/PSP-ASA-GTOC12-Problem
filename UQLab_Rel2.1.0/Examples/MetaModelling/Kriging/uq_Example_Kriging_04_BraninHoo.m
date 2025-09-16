%% KRIGING METAMODELING: BRANIN-HOO FUNCTION
%
% This example showcases how to perform Kriging on the Branin-Hoo function,
% a well-known benchmark function in the field of global optimization. 
% It is a $2$-dimensional function with 
% the particularity of having three global minimas. 
% 
% For more information, see Jones et al. (1998). The Branin-Hoo function is
% also used as a running example in the user's manual of DiceKriging,
% an |R| package for Kriging metamodeling (Roustant et al., 2012).
%
% *References*
%
% * Jones, D. R., M. Schonlau, and W. J. Welch. (1998).
%   Efficient Global Optimization of Expensive BlackBox Functions.
%   Journal of Global Optimization, 13, 455-492.
%   <https://doi.org/10.1023/A:1008306431147 DOI:10.1023/A:1008306431147>
% * Roustant, O., D. Ginsbourger, and Y. Deville. (2012). DiceKriging,
%   DiceOptim: Two R Packages for the Analysis of Computer Experiments by
%   Kriging-Based Metamodeling and Optimization. Journal of Statistical
%   Software, 51(1).
%   <https://doi.org/10.18637/jss.v051.i01 DOI:10.18637/jss.v051.i01>

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
% The Branin-Hoo function is implemented in the UQLab function
% |uq_branin|.
% Create a MODEL object from the function file:
ModelOpts.mFile = 'uq_branin';

myModel = uq_createModel(ModelOpts);

%%
% Type |help uq_branin| for more information on the model structure.

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of two independent uniform random
% variables:
%
% $$X_1 \in \mathcal{U}(-5, 10), \, X_2 \in \mathcal{U}(0, 15)$$

%%
% Specify the marginals and create a UQLab INPUT object:
InputOpts.Marginals(1).Type = 'Uniform';
InputOpts.Marginals(1).Parameters = [-5 10];

InputOpts.Marginals(2).Type = 'Uniform';
InputOpts.Marginals(2).Parameters = [0 15];

myInput = uq_createInput(InputOpts);

%% 4 - KRIGING METAMODEL
%
% Select Kriging as the metamodeling tool:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'Kriging';

%%
% Assign the previously created INPUT and MODEL objects
% to the metamodel options:
MetaOpts.Input = myInput;
MetaOpts.FullModel = myModel;
%%
% If an INPUT object and a MODEL object are specified,
% an experimental design is automatically generated
% and the corresponding model responses are computed.

%%
% Specify the sampling strategy and the number of sample points
% for the experimental design:
MetaOpts.ExpDesign.Sampling = 'LHS';
MetaOpts.ExpDesign.NSamples = 35;

%%
% Use a smooth correlation family, e.g., Matern 5/2:
MetaOpts.Corr.Family = 'Matern-5_2';

%%
% Create the Kriging metamodel:
myKriging = uq_createModel(MetaOpts);

%% 
% Print a report on the resulting Kriging metamodel:
uq_print(myKriging)

%% 5 - VALIDATION

%%
% Create a validation sample of size $10^3$:
Xval = uq_getSample(1e3);

%%
% Evaluate the full model responses at the validation set points:
Yval = uq_evalModel(myModel,Xval);

%%
% Evaluate the Kriging predictor mean at the validation set points:
YKRGmean = uq_evalModel(myKriging,Xval);

%%
% Visualize the full model responses:

% Create a uniform grid on the input parameter space
[x1g,x2g] = meshgrid(linspace(-5, 10, 50),linspace(0, 15, 50));
% Evaluate the full model responses at the validation set points
Yfull = uq_evalModel(myModel,[x1g(:),x2g(:)]);
% Reshape for plotting
Y_full_grid = reshape(Yfull,size(x1g)); 

uq_figure
uq_formatDefaultAxes(gca)
hold on
pcolor(x1g, x2g, Y_full_grid)
shading interp
colorbar
hold off

xlabel('$\mathrm{X_1}$')
ylabel('$\mathrm{X_2}$')
title('$\mathrm{\mathcal{M}(\bf X)}$')

%%
% The Kriging predictor mean and variance can be quickly visualized 
% using the |uq_display| function:
uq_display(myKriging)

%%
% To visually assess the performance of the Kriging metamodel,
% create a scatter plot of the Kriging predictions (i.e., the mean)
% vs. the true responses on the validation set:
uq_figure

uq_plot(Yval, YKRGmean, '+')
hold on
uq_plot([min(Yval) max(Yval)], [min(Yval) max(Yval)], 'k')
hold off

axis equal
axis([min(Yval) max(Yval) min(Yval) max(Yval)])

xlabel('$\mathrm{Y^{true}}$')
ylabel('$\mathrm{\mu_{\widehat{Y}}}^{KRG}$')
