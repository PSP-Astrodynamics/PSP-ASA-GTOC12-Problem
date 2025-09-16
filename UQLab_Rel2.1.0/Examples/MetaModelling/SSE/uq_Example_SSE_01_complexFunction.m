%% SSE METAMODELING: Approximation of complex function
%
% This example showcases how SSE approximates a function with
% non-homogeneous complexity, i.e., a function with complexity that depends
% strongly on the input. It shows an approach with a static experimental
% design and compares the approximation to sparse PCE.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL
%
% We use an analytical function from Marelli et al. (2021):
%
% $$ Y(x) = f_1(x) + f_2(x) $$,
%
% where $x \in [0, 1]$ and $f_1$ and $f_2$ are two terms with different 
% complexity:
%
% $$f_1(x) = -x + 0.1\sin(30x)$$
%
% $$f_2(x) = e^{-(50(x-0.65))^2}$$
%
% This computation is carried out by the function |uq_complexFunction(X)| 
% supplied with UQLab. The function accepts realizations of the input 
% parameter as a vector |X|.

%%
% Create a MODEL from the function file:
ModelOpts.mFile = 'uq_complexFunction';
myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model is a scalar uniform random variable:
%
% $$X \sim \mathcal{U}(0, 1)$$

%%
% Specify this distribution in UQLab:
InputOpts.Marginals.Type = 'Uniform';
InputOpts.Marginals.Parameters = [0 1]; 

%%
% Create an INPUT object based on the specified distribution:
myInput = uq_createInput(InputOpts);

%% 4 - STOCHASTIC SPECTRAL EMBEDDING (SSE) METAMODEL
%
% This section showcases a simple way to calculate a stochastic spectral 
% embedding (SSE) metamodel.

%%
% Select SSE as the metamodeling tool in UQLab:
SSEOpts.Type = 'Metamodel';
SSEOpts.MetaType = 'SSE';

%% 
% Assign the analytical function model as the full computational model 
% of the SSE metamodel:
SSEOpts.FullModel = myModel;

%% 4.1 - Residual expansion technique
%
% In principle, any spectral expansion technique can be used for 
% constructing the residual expansions in SSE (e.g., polynomial chaos, 
% Poincaré, etc.). Currently, PCE is the only supported technique. The SSE
% module uses the |UQLab| PCE module to construct these expansions and
% supports all PCE-specific options.

%%
% Set the expansion options to a degree-adaptive PCE with
% $p\in\{0,\cdots,4\}$:
SSEOpts.ExpOptions.Type = 'Metamodel';
SSEOpts.ExpOptions.MetaType = 'PCE';
SSEOpts.ExpOptions.Degree = 0:4;

%% 4.2 - Given experimental design
%
% If an experimental design is provided, SSE creates residual expansions
% until a specified stopping criterion is met.

%% 
% Let |UQLab| sample the input space and create a space-filling 
% experimental design:
SSEOpts.ExpDesign.Sampling = 'LHS';
SSEOpts.ExpDesign.NSamples = 100;

%%
% Specify the sample size required in a subdomain to create an expansion:
SSEOpts.Refine.NExp = 3;

%% 
% Computing the first two output moments requires computing the flattened 
% SSE representation. This needs some additional computational effort and, 
% therefore, needs to be enabled explicitly:
SSEOpts.PostProcessing.outputMoments = true;

%%
% Create the SSE metamodel:
mySSE = uq_createModel(SSEOpts);

%%
% Print a report on the constructed surrogate:
uq_print(mySSE)

%%
% Create a visual representation of the SSE metamodel:
myFigures = uq_display(mySSE);

%% 5 - POLYNOMIAL CHAOS EXPANSION (PCE) METAMODEL
%
% We compare the SSE performance to PCE on the same experimental design.

%%
% Select degree-adaptive PCE as the metamodeling tool in UQLab:
PCEOpts.Type = 'Metamodel';
PCEOpts.MetaType = 'PCE';
PCEOpts.Degree = 0:12;

%%
% Choose the same experimental design that was used to construct |mySSE|:
PCEOpts.ExpDesign.X = mySSE.ExpDesign.X;
PCEOpts.ExpDesign.Y = mySSE.ExpDesign.Y;

%%
% Create the PCE metamodel:
myPCE = uq_createModel(PCEOpts);

%% 6 - VALIDATION OF THE METAMODELS

%% 6.1 - Generation of a validation set
%
% Create a validation sample of size $10^4$ from the input model:
Xval = uq_getSample(1e4);

%%
% Evaluate the full model response at the validation sample points:
Yval = uq_evalModel(myModel,Xval);

%%
% Evaluate the corresponding responses for each of the metamodels created 
% before:
YSSE = uq_evalModel(mySSE,Xval);
YPCE = uq_evalModel(myPCE,Xval);

%%
% Store the metamodels responses in |YContainer|:
YContainer = {YPCE, YSSE};

%% 6.2 - Computation of the validation error
%
% Compute the validation error for the PCE and SSE metamodels.
mySSEs = {myPCE, mySSE};
methodLabels = {'PCE', 'SSE'};

fprintf('Validation error:\n')
fprintf('%20s | Rel. error | ED size\n', 'Method')
fprintf('--------------------------------------------\n')
for ii = 1:length(YContainer)
    normEmpErr = mean((Yval - YContainer{ii}).^2)/var(Yval);
    fprintf('%20s | %10.2e | %7d\n', methodLabels{ii}, normEmpErr, mySSEs{ii}.ExpDesign.NSamples);
end

%% 6.3 - Comparison of the results
%
% To visually assess the performance of each metamodel, we add a plot of 
% the PCE response to the SSE plot:
plotAx = myFigures{1}.Children(2);
plotPCEX = plotAx.Children(2).XData.';
plotPCEY = uq_evalModel(myPCE, plotPCEX);
uq_plot(plotAx, plotPCEX, plotPCEY,'Color',[1 1 1]*0.7,'DisplayName','$\mathcal{M}_{\mathrm{PCE}}$')

%%
%
% Additionally, we create scatter plots of the metamodel vs. the true 
% response on the validation sets:
uq_figure('Name', 'Metamodels vs. true model')

for ii = 1:length(YContainer)
    subplot(1,length(YContainer),ii)
    uq_plot(Yval, YContainer{ii}, '+')
    hold on
    uq_plot([min(Yval) max(Yval)], [min(Yval) max(Yval)], 'k')
    hold off
    axis equal 
    axis([min(Yval) max(Yval) min(Yval) max(Yval)]) 
    
    title(methodLabels{ii})
    xlabel('$\mathrm{Y_{true}}$')
    if strcmpi(methodLabels{ii},'PCE')
        ylabel('$\mathrm{Y_{PCE}}$')
    else
        ylabel('$\mathrm{Y_{SSE}}$')
    end
end

%%
% *References*
%
% * Marelli, S., Wagner, P.-R., Lataniotis, C., Sudret, B., Stochastic 
%   spectral embedding, International Journal for Uncertainty 
%   Quantification, 11(2):25–47(2021). 
%   DOI: <https://doi.org/10.1615/Int.J.UncertaintyQuantification.2020034395 10.1615/Int.J.UncertaintyQuantification.2020034395>