%% LRA METAMODELING: ISHIGAMI FUNCTION
%
% This example showcases an application of a canonical 
% low-rank approximation (LRA) to the metamodeling 
% of the Ishigami function.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(150,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL
%
% The Ishigami function is defined as:
%
% $$Y(\mathbf{x}) = \sin(x_1) + 7 \sin^2(x_2) + 0.1 x_3^4 \sin(x_1)$$

%%
% This computation is carried out by the function
% |uq_ishigami(X)| supplied with UQLab.
% The function evaluates the inputs gathered in the $N \times M$ matrix
% |X|, where $N$ and $M$ are the numbers of realizations and input
% variables, respectively.
% 
% Create a MODEL object from the |uq_ishigami| function:
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
% Create an INPUT object based on the marginals:
myInput = uq_createInput(InputOpts);

%% 4 - LOW-RANK APPROXIMATION (LRA) METAMODEL
%
% Select the metamodeling tool and the LRA module:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'LRA';

%%
% Specify the range for the univariate polynomials degree selection:
MetaOpts.Degree = 3:20;             

%%  
% In this example, the rank is adapted and the optimal rank is selected 
% based on the 3-fold cross-validation.
% Specify the range for the rank selection:
MetaOpts.Rank = 1:20;

%%
% Specify the adaptation strategy (i.e., rank adaptivity):
MetaOpts.Adaptivity = 'all_d_adapt_r';

%%
% Configure UQLab to generate an experimental design of size $5'000$
% based on the latin hypercube sampling:
MetaOpts.ExpDesign.NSamples = 5e3;
MetaOpts.ExpDesign.Sampling = 'LHS';

%%
% Create the LRA metamodel:
myLRA = uq_createModel(MetaOpts);

%% 
% Print some basic information about the LRA metamodel:
uq_print(myLRA)

%%
% Retrieve useful results:
R = myLRA.LRA.Basis.Rank;  % optimal rank
errCV = myLRA.Error.SelectedCVScore;  % 3-fold cross-validation error

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
