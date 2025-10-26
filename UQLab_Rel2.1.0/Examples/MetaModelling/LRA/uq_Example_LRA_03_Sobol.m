%% LRA METAMODELING: SOBOL' FUNCTION
%
% This example showcases an application of a canonical 
% low-rank approximation (LRA) to the metamodeling 
% of the 8-dimensional Sobol' function.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL
%
% The Sobol' function is defined as:
% 
% $$Y(\mathbf{X}) = \prod_{k=1}^{8} \frac{|4X_k-2|+c_k}{1+c_k}$$
%
% with $c_k = \{ 1, 2, 5, 10, 20, 50, 100, 500 \}.$
%
% This computation is carried out by the function
% |uq_sobol(X)| supplied with UQLab.
% The function evaluates the inputs gathered in the $N \times M$
% matrix |X|, where $N$ and $M$ are the numbers of realizations and input
% variables. 
% 
% Create a MODEL object that uses the |uq_sobol| function:
ModelOpts.mFile = 'uq_sobol';

myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of eight independent uniform 
% random variables:
%
% $$X_i \sim \mathcal{U}(0, 1), \quad i = 1,\ldots,8$$
%
% Specify these marginals in UQLab:
for i = 1:8
    InputOpts.Marginals(i).Type = 'Uniform';
    InputOpts.Marginals(i).Parameters = [0 1];
end

%%
% Create an INPUT object based on the marginals:
myInput = uq_createInput(InputOpts);

%% 4 - LOW-RANK APPROXIMATION (LRA) METAMODEL
%
% Select the metamodeling tool and the LRA metamodel:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'LRA';

%%
% Specify the range for the rank selection:
MetaOpts.Rank = 1:10;

%%
% Specify the range for the polynomial degree selection:
MetaOpts.Degree = 1:20;

%%
% Configure UQLab to generate an experimental design of size $10^3$
% based on the latin hypercube sampling
% (also available: 'MC', 'Sobol', 'Halton'):
MetaOpts.ExpDesign.NSamples = 1e3;
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

%% 5 - VALIDATION
%
% Create a validation set:
Nval = 1e6;
Xval = uq_getSample(Nval,'MC');
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

xlim([min(Yval) max(Yval)])
ylim([min(Yval) max(Yval)])

xlabel('$\mathrm{Y}$')
ylabel('$\mathrm{\widehat{Y}^{\rm LRA}}$')
title(['R = ', num2str(R),', ',...
    '$\mathrm{\widehat{err}_G}$ = ', num2str(errG), ', ',...
    '$\mathrm{err_{\rm CV}}$ = ', num2str(errCV)])
