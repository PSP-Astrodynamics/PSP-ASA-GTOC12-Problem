%% PCE METAMODELING: CONSTRUCTION OF ORTHOGONAL BASIS FOR ARBITRARY DISTRIBUTION
%
% This example demonstrates the numerical basis construction with 
% Stieltjes procedure. The Ishigami function with Gaussian distributions 
% restricted to the $[-\pi, \pi]$ interval is used.
% The Stieltjes procedure is expected to produce a basis
% that performs better than the Legendre polynomials,
% the default basis for all bounded distribution.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL
%
% The Ishigami function is defined as:
%
% $$Y(\mathbf{x}) = \sin(x_1) + 7 \sin^2(x_2) + 0.1 x_3^4 \sin(x_1)$$
%
% where $x_i \in [-\pi, \pi], \; i = 1,2,3.$

%%
% This computation is carried out by the function
% |uq_ishigami(X)| supplied with UQLab.
% The function evaluates the inputs given in $N \times M$ matrix |X|,
% where $N$ and $M$ are the number of realizations and input variables,
% respectively.
% 
% Create a MODEL object from the |uq_ishigami| function:
ModelOpts.mFile = 'uq_ishigami';      
myModel = uq_createModel(ModelOpts);  

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of three independent bounded 
% Gaussian random variables:
%
% $$X_i \sim \mathcal{N}(\pi/2, \pi), \; X_i \in [-\pi, \pi], \; i = 1,2,3$$

%%
% Specify these marginals:
for ii = 1:3
    InputOpts.Marginals(ii).Type = 'Gaussian';
    InputOpts.Marginals(ii).Parameters = [pi/2 pi];
    InputOpts.Marginals(ii).Bounds = [-pi pi];
end

%%
% Create an INPUT object based on the specified marginals:
myInput = uq_createInput(InputOpts);

%% 4 - POLYNOMIAL CHAOS EXPANSION (PCE) METAMODEL
%
% Select PCE as the metamodeling tool:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'PCE';

%% 
% Assign the Ishigami function model as the full computational model 
% of the PCE metamodel:
MetaOpts.FullModel = myModel;

%% 4.1 PCE with Legendre polynomials
%
% A PCE metamodel constructed using the Legendre polynomials is calculated 
% with the sparse-favouring least-square minimization LARS.
% Enable the 'LARS' method (also available:  'OLS', 'Quadrature'):
MetaOpts.Method = 'LARS';

%%
% Least-square methods allow for degree-adaptive calculation of the PCE
% coefficients. That is, if an array of possible degrees is given,
% the degree with the lowest Leave-One-Out cross-validation error
% (LOO error) is automatically selected.
% Specify the range for the degree selection:
MetaOpts.Degree = 2:15;

%%
% Least-square methods rely on the evaluation of the model response on an
% experimental design. The following options configure UQLab to generate an
% experimental design of size $150$ based on a latin hypercube sampling of
% the input model (also available: 'MC', 'Sobol', 'Halton'):
MetaOpts.ExpDesign.NSamples = 150;
MetaOpts.ExpDesign.Sampling = 'LHS';

%%
% Manually specify the univariate polynomials to the "Legendre" family to
% compare the performance of the construction with the "arbitrary" basis:
MetaOpts.PolyTypes = {'legendre','legendre','legendre'};

%%
% Create the PCE metamodel:
myPCE_Isop = uq_createModel(MetaOpts);

%%
% Print a summary of the calculated coefficients:
uq_print(myPCE_Isop)

%%
% Display the summary graphically:
uq_display(myPCE_Isop)

%% 4.2 PCE with numerically estimated polynomials
%
% Set the polynomial families to "arbitrary", so that polynomials
% orthogonal to the input marginals are numerically constructed:
MetaOpts.PolyTypes = {'arbitrary','arbitrary','arbitrary'};

%%
% Reset the random seed to obtain the same experimental design as before:
rng(100,'twister')

%%
% Create the PCE metamodel:
myPCE_Arb = uq_createModel(MetaOpts);

%%
% Print a summary of the calculated coefficients:
uq_print(myPCE_Arb)

%%
% Display the summary graphically:
uq_display(myPCE_Arb)

%% 5 - RESULTS

%% 5.1 Generation of a validation set:
%
% Create a validation sample:
Nval = 1e4;
Xval = uq_getSample(Nval);

%%
% Evaluate the full model response at the validation sample points:
Yval = uq_evalModel(myModel,Xval);

%%
% Evaluate the corresponding responses for each of the two PCE metamodels:
Y_Isop = uq_evalModel(myPCE_Isop,Xval);
Y_Arb = uq_evalModel(myPCE_Arb,Xval);

%% 5.2 Comparison of the results
%
% To visually assess the performance of each metamodel,
% produce scatter plots of the metamodel vs. the true response
% on the validation sample.

%%
% * Legendre polynomials:
uq_figure
uq_plot(Yval, Y_Isop, '+')
hold on
uq_plot([min(Yval) max(Yval)], [min(Yval) max(Yval)], 'k')
hold off
axis equal
axis([min(Yval) max(Yval) min(Yval) max(Yval)])

xlabel('$\mathrm{Y}$')
ylabel('$\mathrm{Y^{PC}_{Isop}}$')

%%
% * Polynomials computed by the Stieltjes procedure:
uq_figure
uq_plot(Yval, Y_Arb, '+')
hold on
uq_plot([min(Yval) max(Yval)], [min(Yval) max(Yval)], 'k')
hold off
axis equal
axis([min(Yval) max(Yval) min(Yval) max(Yval)])

xlabel('$\mathrm{Y}$')
ylabel('$\mathrm{Y^{PC}_{Arb}}$')
