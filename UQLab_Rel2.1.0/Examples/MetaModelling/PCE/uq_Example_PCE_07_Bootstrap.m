%% PCE METAMODELING: BOOTSTRAP PCE FOR LOCAL ESTIMATION
%
% This example showcases the creation and use of a bootstrap polynomial
% chaos expansion (bPCE).
% The full computational model model is an analytical non-linear, 
% non-monotonic function.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL
%
% The full computational model is a simple analytical function defined by:
%
% $$\mathcal{M}(X) = X \sin(X)$$
%
% where $X \in [0, 15]$.

%%
% Create a MODEL object using a string:
ModelOpts.mString = 'X.*sin(X)';
myFullModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of a uniform random variable:
%
% $$X \sim \mathcal{U}(0, 15)$$

%%
% Specify the probabilistic model of the input variable:
InputOpts.Marginals(1).Type = 'Uniform';
InputOpts.Marginals(1).Parameters = [0 15];

%%
% Create the INPUT object:
myInput = uq_createInput(InputOpts);

%% 4 - BOOTSTRAP POLYNOMIAL CHAOS EXPANSION (bPCE) METAMODEL
%
% Select PCE as the metamodeling tool:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'PCE';

%%
% Specify the degree of the expansion:
MetaOpts.Degree = 11;

%%
% Specify the number of points in the experimental design:
MetaOpts.ExpDesign.NSamples = 15;

%%
% Enable bootstrapping by specifying the number of bootstrap replications:
MetaOpts.Bootstrap.Replications = 100;

%%
% Create the PCE metamodel:
myPCE = uq_createModel(MetaOpts);

%% 5 - VALIDATION OF THE METAMODEL
%
% Create a validation sample on a regular grid:
Xval = linspace(0, 15, 1000)';

%%
% Evaluate the true model on the validation sample:
Yval = uq_evalModel(myFullModel,Xval);

%%
% Evaluate the PCE metamodel and the corresponding bootstrap replications
% on the validation sample:
[YPCval,YPC_var,YPCval_Bootstrap] = uq_evalModel(myPCE,Xval);

%%
% Create plots with confidence bounds (based on empirical quantiles)
% and bootstrap replications:
uq_figure
p(1) = uq_plot(Xval, Yval, 'k');
hold on
cmap = get(gca,'ColorOrder');
p(2) = uq_plot(Xval,YPCval);
p(3) = uq_plot(...
    Xval, quantile(YPCval_Bootstrap,0.025,2), '--',...
    'Color', cmap(1,:));
p(4) = uq_plot(...
    Xval, quantile(YPCval_Bootstrap,0.975,2), '--',...
    'Color', cmap(1,:));
p(5) = uq_plot(...
    myPCE.ExpDesign.X, myPCE.ExpDesign.Y, 'ko',...
    'MarkerSize', 5);
pb = uq_plot(...
    Xval, YPCval_Bootstrap',...
    'LineWidth', 0.5, 'Color', cmap(2,:));
h = get(gca, 'Children');
set(gca, 'Children', h(end:-1:1))  % Reorder the lines in the plot
hold off
% Add labels and a legend
xlabel('$\mathrm{X}$')
ylabel('$\mathcal{M}(X)$')
uq_legend(...
    [p([5 1:3]) pb(1)],...
    {'Exp Design', 'True', 'PCE', '95\% Confidence Bounds', 'Replications'})
