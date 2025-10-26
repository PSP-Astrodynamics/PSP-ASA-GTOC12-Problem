%% PCE METAMODELING: EXPERIMENTAL DESIGN OPTIONS
%
% This example shows different methods to create an experimental design
% and calculate PCE coefficients with the sparse-favoring 
% least-square minimization strategy.
% The full computational model of choice is the Ishigami function,
% a standard benchmark in PCE applications.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(120,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL
%
% The Ishigami function is defined as:
%
% $$Y(\mathbf{x}) = \sin(x_1) + 7 \sin^2(x_2) + 0.1 x_3^4 \sin(x_1)$$
%
% where $x_i \in [-\pi, \pi], \; i = 1,2,3.$
%
% This computation is carried out by the function
% |uq_ishigami(X)| supplied with UQLab.
% The input variables of this function are gathered into the $N \times M$
% matrix |X|, where $N$ and $M$ are the numbers of realizations
% and input variables, respectively.
% 
% Create a MODEL from the function file:
ModelOpts.mFile = 'uq_ishigami';
myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of three independent uniform 
% random variables:
%
% $$X_i \sim \mathcal{U}(-\pi, \pi), \quad i = 1,2,3$$

%%
% Specify the marginals:
for ii = 1:3
    InputOpts.Marginals(ii).Type = 'Uniform';
    InputOpts.Marginals(ii).Parameters = [-pi pi]; 
end

%%
% Create an INPUT object based on the specified marginals:
myInput = uq_createInput(InputOpts);

%% 4 - POLYNOMIAL CHAOS EXPANSION (PCE) METAMODEL
%
% In this section, a sparse polynomial chaos expansion (PCE) is created
% to surrogate the Ishigami function.
% The method of choice is the sparse-favouring least-square minimization
% strategy LARS.
%
% Select PCE as the metamodeling tool and LARS as the calculation strategy:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'PCE';
MetaOpts.Method = 'LARS' ;

%% 
% Assign the Ishigami function model as the full computational model 
% of the PCE metamodel:
MetaOpts.FullModel = myModel;

%%
% LARS allows for degree-adaptive calculation of the PCE
% coefficients. That is, if an array of possible degrees is given,
% the degree with the lowest Leave-One-Out (LOO) cross-validation error
% is automatically selected.
% Specify the range for the degree selection:
MetaOpts.Degree = 3:15;

%%
% Comparison of the performance of the metamodels created below is done by
% comparing the response of the full model and each of the metamodels
% on a validation set. Generate a validation set of size $10^4$:
Xval = uq_getSample(1e4);

%%
% Calculate the response of the exact Ishigami model at the validation set 
% points for reference:
Yval = uq_evalModel(myModel,Xval);

%% 5 - COMPARISON OF DIFFERENT EXPERIMENTAL DESIGN SIZES
%
% Least-square methods rely on the evaluation of the model response on an
% experimental design. The following options configure UQLab to generate an
% experimental design of size $20$ based on a latin hypercube sampling of
% the input model (also available: 'MC', 'Sobol', 'Halton'):
MetaOpts.ExpDesign.NSamples = 20;
MetaOpts.ExpDesign.Sampling = 'LHS';

%%
% Create the PCE metamodel based on the design of size $20$: 
myPCE_LHS_20 = uq_createModel(MetaOpts);

%% 
% Create additional PCE metamodels with an increasing number of points
% in the experimental design: $40$, $80$, and $120$ sample points;
% with all the other options are left unchanged:
MetaOpts.ExpDesign.NSamples = 40;
myPCE_LHS_40 = uq_createModel(MetaOpts);

MetaOpts.ExpDesign.NSamples = 80;
myPCE_LHS_80 = uq_createModel(MetaOpts);

MetaOpts.ExpDesign.NSamples = 120;
myPCE_LHS_120 = uq_createModel(MetaOpts);

%%
% Calculate the responses of the created metamodels:
Y_LHS_20 = uq_evalModel(myPCE_LHS_20,Xval);
Y_LHS_40 = uq_evalModel(myPCE_LHS_40,Xval);
Y_LHS_80 = uq_evalModel(myPCE_LHS_80,Xval);
Y_LHS_120 = uq_evalModel(myPCE_LHS_120,Xval);
Y_LHS = {Y_LHS_20, Y_LHS_40, Y_LHS_80, Y_LHS_120};

%%
% Create plots for visual comparison between all the metamodels
% created with different sample sizes: 
uq_figure
nLabels = {'N = 20', 'N = 40', 'N = 80', 'N = 120'};
for i = 1:4
    subplot(2, 2, i)
    uq_plot(Yval, Y_LHS{i}, '+')
    hold on
    uq_plot([min(Yval) max(Yval)], [min(Yval) max(Yval)], 'k')
    hold off
    axis equal 
    axis([min(Yval) max(Yval) min(Yval) max(Yval)]) 
    title(nLabels{i})
    xlabel('$\mathrm{Y_{true}}$')
    ylabel('$\mathrm{Y_{PC}}$')
end

%% 6 - COMPARISON OF DIFFERENT SAMPLING STRATEGIES
%
% Create additional metamodels with experimental designs of fixed size
% ($N = 80$) based on different sampling strategies (Monte Carlo sampling, 
% Sobol', and Halton' sequences):
MetaOpts.ExpDesign.NSamples = 80;

MetaOpts.ExpDesign.Sampling = 'MC';
myPCE_MC_80 = uq_createModel(MetaOpts);

MetaOpts.ExpDesign.Sampling = 'Sobol';
myPCE_Sobol_80 = uq_createModel(MetaOpts);

MetaOpts.ExpDesign.Sampling = 'Halton';
myPCE_Halton_80 = uq_createModel(MetaOpts);

%%
% Calculate the responses of the created metamodels:
Y_MC_80 = uq_evalModel(myPCE_MC_80,Xval);
Y_Sobol_80 = uq_evalModel(myPCE_Sobol_80,Xval);
Y_Halton_80 = uq_evalModel(myPCE_Halton_80,Xval);
Y_80 = {Y_LHS_80, Y_MC_80, Y_Sobol_80, Y_Halton_80};

%%
% Create plots for visual comparison between all the metamodels
% created with different sampling strategies: 
uq_figure
strategyLabels = {'LHS', 'MC', 'Sobol''', 'Halton'};
for i = 1:4
    subplot(2, 2, i)
    uq_plot(Yval, Y_80{i}, '+')
    hold on
    uq_plot([min(Yval) max(Yval)], [min(Yval) max(Yval)], 'k')
    hold off
    axis equal 
    axis([min(Yval) max(Yval) min(Yval) max(Yval)]) 
    title(strategyLabels{i})
    xlabel('$\mathrm{Y_{true}}$')
    ylabel('$\mathrm{Y_{PC}}$')
end