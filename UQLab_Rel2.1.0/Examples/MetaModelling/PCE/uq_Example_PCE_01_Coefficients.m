%% PCE METAMODELING: COMPARISON OF PCE CALCULATION STRATEGIES
%
% This example showcases how various strategies for the computation of
% polynomial chaos expansion (PCE) coefficients can be deployed in UQLab.
% The performance of the resulting metamodels are also compared.
% The full computational model of choice is the Ishigami function,
% a standard benchmark in PCE applications.

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
%
% This computation is carried out by the function
% |uq_ishigami(X)| supplied with UQLab.
% The input parameters of this function are gathered into the vector |X|.
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
% Specify these marginals in UQLab:
for ii = 1:3
    InputOpts.Marginals(ii).Type = 'Uniform';
    InputOpts.Marginals(ii).Parameters = [-pi pi]; 
end

%%
% Create an INPUT object based on the specified marginals:
myInput = uq_createInput(InputOpts);

%% 4 - POLYNOMIAL CHAOS EXPANSION (PCE) METAMODELS
%
% This section showcases several ways to calculate the polynomial
% chaos expansion (PCE) coefficients.

%%
% Select PCE as the metamodeling tool in UQLab:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'PCE';

%% 
% Assign the Ishigami function model as the full computational model 
% of the PCE metamodel:
MetaOpts.FullModel = myModel;

%% 4.1 Quadrature-based calculation of the coefficients
%
% Quadrature-based methods automatically use the computational model
% created earlier to gather the model responses on the quadrature nodes.

%%
% Specify the 'Quadrature' calculation method
% (by default, Smolyak' sparse quadrature is used):
MetaOpts.Method = 'Quadrature';

%%
% Specify the maximum polynomial degree:
MetaOpts.Degree = 14;
%%
% UQLab will automatically determine the appropriate quadrature level.

%% 
% Create the quadrature-based PCE metamodel:
myPCE_Quadrature = uq_createModel(MetaOpts);

%%
% Print a report on the calculated coefficients:
uq_print(myPCE_Quadrature)

%%
% Create a visual representation of the distribution of the coefficients:
uq_display(myPCE_Quadrature)
fig = gcf;
fig.Name = 'Polynomial Spectrum for the quadrature method';

%% 4.2 Least-square calculation of the coefficients
%
% Specify 'OLS' (ordinary least-squares) as the PCE calculation method:
MetaOpts.Method = 'OLS';

%%
% Least-square methods allow for degree-adaptive calculation of the PCE
% coefficients. That is, if an array of possible degrees is given,
% the degree with the lowest Leave-One-Out cross-validation error
% (LOO error) is automatically selected.
% Specify the range for the degree selection:
MetaOpts.Degree = 3:15;

%% 
% Least-square methods rely on the evaluation of the model response on an
% experimental design. The following options configure UQLab to generate an
% experimental design of size $500$ based on a latin hypercube sampling of
% the input model (also available: 'MC', 'Sobol', 'Halton'):
MetaOpts.ExpDesign.NSamples = 500;
MetaOpts.ExpDesign.Sampling = 'LHS';

%%
% Create the OLS-based PCE metamodel:
myPCE_OLS = uq_createModel(MetaOpts);

%%
% Print a report on the calculated coefficients:
uq_print(myPCE_OLS)

%%
% Create a visual representation of the distribution of the coefficients:
uq_display(myPCE_OLS)
fig = gcf;
fig.Name = 'Polynomial Spectrum for OLS';

%% 4.3 Sparse Least-Angle-Regression-based (LARS) calculation of the coefficients
%
% The sparse-favoring least-square minimization LARS can be enabled
% similarly to OLS:
MetaOpts.Method = 'LARS';

%%
% LARS allows for degree-adaptive calculation of the PCE
% coefficients. That is, if an array of possible degrees is given,
% the degree with the lowest Leave-One-Out cross-validation error
% (LOO error) is automatically selected.
% Specify the range for the degree selection:
MetaOpts.Degree = 3:15;

%% 
% Specify a sparse truncation scheme (hyperbolic norm with $q = 0.75$):
MetaOpts.TruncOptions.qNorm = 0.75;

%%
% In general, sparse PCE requires a vastly inferior number of sample points
% to properly converge with respect to both the quadrature and OLS methods:
MetaOpts.ExpDesign.NSamples = 150;

%%
% Create the LARS-based PCE metamodel:
myPCE_LARS = uq_createModel(MetaOpts);

%%
% Print a report on the calculated coefficients:
uq_print(myPCE_LARS)

%%
% Create a visual representation of the distribution of the coefficients:
uq_display(myPCE_LARS)
fig = gcf;
fig.Name = 'Polynomial Spectrum for LARS';

%% 4.4 Orthogonal Matching Pursuit (OMP) calculation of the coefficients
%
% The Orthogonal Matching Pursuit Algorithm (OMP) can be enabled
% similarly to the other PCE calculation methods:
MetaOpts.Method = 'OMP';

%%
% OMP allows for degree-adaptive calculation of the PCE
% coefficients. That is, if an array of possible degrees is given,
% the degree with the lowest Leave-One-Out cross-validation error
% (LOO error) is automatically selected.
% Specify the range for the degree selection:
MetaOpts.Degree = 3:15;

%% 
% Specify a sparse truncation scheme (hyperbolic norm with q = 0.75):
MetaOpts.TruncOptions.qNorm = 0.75;

%%
% Create the OMP-based PCE metamodel:
myPCE_OMP = uq_createModel(MetaOpts);

%%
% Print a report on the calculated coefficients:
uq_print(myPCE_OMP)

%%
% Create a visual representation of the distribution of the coefficients:
uq_display(myPCE_OMP)
fig = gcf;
fig.Name = 'Polynomial Spectrum for OMP';

%% 4.5 Subspace Pursuit (SP) calculation of the coefficients
%
% The Subspace Pursuit Algorithm (SP) can be enabled
% similarly to the other PCE calculation methods:
MetaOpts.Method = 'SP';

%%
% SP allows for degree-adaptive calculation of the PCE
% coefficients. That is, if an array of possible degrees is given,
% the degree with the lowest Leave-One-Out cross-validation error
% (LOO error) is automatically selected.
% Specify the range for the degree selection:
MetaOpts.Degree = 3:15;

%% 
% Specify a sparse truncation scheme (hyperbolic norm with q = 0.75):
MetaOpts.TruncOptions.qNorm = 0.75;

%%
% Create the SP-based PCE metamodel:
myPCE_SP = uq_createModel(MetaOpts);

%%
% Print a report on the calculated coefficients:
uq_print(myPCE_SP)

%%
% Create a visual representation of the distribution of the coefficients:
uq_display(myPCE_SP)
fig = gcf;
fig.Name = 'Polynomial Spectrum for SP';


%% 4.6 Bayesian Compressive Sensing (BCS) calculation of the coefficients
%
% The Bayesian Compressive Sensing Algorithm (BCS) can be enabled
% similarly to the other PCE calculation methods:
MetaOpts.Method = 'BCS';

%%
% BCS allows for degree-adaptive calculation of the PCE
% coefficients. That is, if an array of possible degrees is given,
% the degree with the lowest Leave-One-Out cross-validation error
% (LOO error) is automatically selected.
% Specify the range for the degree selection:
MetaOpts.Degree = 3:15;

%% 
% Specify a sparse truncation scheme (hyperbolic norm with q = 0.75):
MetaOpts.TruncOptions.qNorm = 0.75;

%%
% Create the BCS-based PCE metamodel:
myPCE_BCS = uq_createModel(MetaOpts);

%%
% Print a report on the calculated coefficients:
uq_print(myPCE_BCS)

%%
% Create a visual representation of the distribution of the coefficients:
uq_display(myPCE_BCS)
fig = gcf;
fig.Name = 'Polynomial Spectrum for BCS';


%% 5 - VALIDATION OF THE METAMODELS

%% 5.1 Generation of a validation set
%
% Create a validation sample of size $10^4$ from the input model:
Xval = uq_getSample(1e4);

%%
% Evaluate the full model response at the validation sample points:
Yval = uq_evalModel(myModel,Xval);

%%
% Evaluate the corresponding responses
% for each of the three PCE metamodels created before:
YQuadrature = uq_evalModel(myPCE_Quadrature,Xval);
YOLS = uq_evalModel(myPCE_OLS,Xval);
YLARS = uq_evalModel(myPCE_LARS,Xval);
YOMP = uq_evalModel(myPCE_OMP,Xval);
YSP = uq_evalModel(myPCE_SP,Xval);
YBCS = uq_evalModel(myPCE_BCS,Xval);
YPCE = {YQuadrature, YOLS, YLARS, YOMP, YSP, YBCS};

%% 5.2 Comparison of the results
%
% To visually assess the performance of each metamodel, produce scatter
% plots of the metamodel vs. the true response on the validation set:
uq_figure
methodLabels = {'Quadrature', 'OLS', 'LARS', 'OMP', 'SP', 'BCS'};

for i = 1:length(YPCE)

    subplot(2,3,i)
    uq_plot(Yval, YPCE{i}, '+')
    hold on
    uq_plot([min(Yval) max(Yval)], [min(Yval) max(Yval)], 'k')
    hold off
    axis equal 
    axis([min(Yval) max(Yval) min(Yval) max(Yval)]) 
    
    title(methodLabels{i})
    xlabel('$\mathrm{Y_{true}}$')
    ylabel('$\mathrm{Y_{PC}}$')

end

%% 5.3 Computation of the validation error
myPCEs = {myPCE_Quadrature, myPCE_OLS, myPCE_LARS, myPCE_OMP, myPCE_SP, myPCE_BCS};

fprintf('Validation error:\n')
fprintf('%10s | Rel. error | ED size\n', 'Method')
fprintf('---------------------------------\n')
for i = 1:length(YPCE)
    fprintf('%10s | %10.2e | %7d\n', methodLabels{i}, mean((Yval - YPCE{i}).^2)/var(Yval), myPCEs{i}.ExpDesign.NSamples);
end
