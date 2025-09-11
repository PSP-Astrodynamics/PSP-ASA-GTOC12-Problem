%% MODEL MODULE: COMPUTATIONAL MODEL PARAMETERS
%
% This example showcases how to pass parameters in a computational model.

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
% $$Y(\mathbf{x}) = \sin(x_1) + a \sin^2(x_2) + b x_3^4 \sin(x_1)$$
%
% where $x_i \in [-\pi, \pi], \; i = 1,2,3$;
% and $a$ and $b$ are model parameters.
%
% This computation is carried out by the function
% |uq_ishigami(X,P)| supplied with UQLab.
% The inputs and model parameters of this function are gathered
% into the $N \times M$ matrix |X| and into the $2$-dimensional vector |P|,
% respectively; and where $N$ and $M$ are the numbers of realizations and
% inputs, respectively.

%%
% Specify the function in the options for MODEL object:
ModelOpts.mFile = 'uq_ishigami';

%%
% First, a typical parameter set is chosen, $[a, b] = [7, 0.1]$:
ModelOpts.Parameters = [7 0.1];

%%
% Create a MODEL object:
myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of
% three independent uniform random variables:
%
% $X_i \sim \mathcal{U}(-\pi, \pi), \quad i = 1,2,3$

%%
% Specify the marginals (if no copula is given,
% they are assumed independent): 
for ii = 1:3
    InputOpts.Marginals(ii).Type = 'Uniform';
    InputOpts.Marginals(ii).Parameters = [-pi pi]; 
end

%%
% Create an INPUT object based on the marginals:
myInput = uq_createInput(InputOpts);

%% 4 - COMPARISON OF THE MODEL RESPONSES FOR VARIOUS PARAMETER SETS

%% 4.1 Using a fixed parameter set
%
% Create a validation sample of size $10^4$ from the input model
% using latin hypercube sampling (LHS):
X = uq_getSample(1e4,'LHS');

%%
% Evaluate the corresponding responses of the computational model at the
% validation sample points:
Y = uq_evalModel(myModel,X);

%%
% Plot a histogram of the model responses:
uq_figure
uq_histogram(Y)
xlabel('$\mathrm Y$')
ylabel('Frequency')

%% 4.2 Using different parameter sets
%
% Create multiple combinations of model parameters values in a matrix:
parameterValues = ...
    [7, 0.1;
     6, 0.1;
     6, 0.2;
     7, 0.05];

%%
% Create the histograms of the model responses for each set of 
% model parameter values:
uq_figure

% Loop through each parameter set
for ii = 1:length(parameterValues)
    % Assign the corresponding parameters
    myModel.Parameters = parameterValues(ii,:);

    % Evaluate the computational model's responses
    Y =  uq_evalModel(myModel,X);

    % Plot the histogram of the responses in a separate subplot
    subplot(2,2,ii)
    uq_formatDefaultAxes(gca);
    h = uq_histogram(Y);
    defcolors = get(gca,'ColorOrder');
    set(h, 'FaceColor', defcolors(ii,:));
    % Set title and labels
    xlabel('$\mathrm{Y}$')
    ylabel('Frequency')
    title(sprintf('a=%.2f, b=%.2f', parameterValues(ii,1),...
        parameterValues(ii,2)))
end
