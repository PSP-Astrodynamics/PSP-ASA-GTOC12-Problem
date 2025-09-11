%% MODEL MODULE: COMPUTATIONAL MODEL DEFINITION
%
% This example showcases the various ways to define a computational
% model in UQLab using the analytical Ishigami function
% as the computational model.

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
% The Model module in UQLab offers three ways
% to define a computational model:
%
% * using an m-file
% * using a function handle
% * using a string

%%
% Each of these will be illustrated next to define the Ishigami function
% as a computational model in UQLab. 

%% 2.1 Using an m-file
%
% The Ishigami function is available in UQLab as |uq_ishigami(X)|.
% It is located in:
%
%   <uq_rootPath>/Examples/SimpleTestFunctions/uq_ishigami.m
%
% |uq_rootPath| depends on the user's UQLab local installation.
%
% The function evaluates the inputs given in the $N \times M$ matrix |X|,
% where $N$ and $M$ are the numbers of realizations and inputs,
% respectively.
% 
% Specify the |uq_ishigami| function in the options for the MODEL object:
Model1Opts.mFile = 'uq_ishigami';

%%
% Create the MODEL object:
myModel_mFile = uq_createModel(Model1Opts);

%% 2.2 Using a function handle
%
% The already available |uq_ishigami| function can also be defined
% using function handles:
Model2Opts.mHandle = @uq_ishigami;

%%
% Create the MODEL object:
myModel_mHandle = uq_createModel(Model2Opts);

%% 2.3 Using a string
%
% Finally, the Ishigami function can also be specified
% using a string of MATLAB expression as follows:
Model3Opts.mString = ['sin(X(:,1)) + 7*(sin(X(:,2)).^2)',...
    '+ 0.1*(X(:,3).^4).* sin(X(:,1))'];

%%
% The MATLAB expression in the string is vectorized,
% hence vectorization can be activated:
Model3Opts.isVectorized = true;

%%
% Create the MODEL object:
myModel_mString = uq_createModel(Model3Opts);

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
% Create an INPUT object based on the marginals:
myInput = uq_createInput(InputOpts);

%% 4 - COMPARISON OF THE MODELS
%
% To compare models created using the three different ways, 
% create a sample of size $10^4$ from the input model
% using the latin hypercube sampling (LHS):
X = uq_getSample(1e4,'LHS');

%%
% Evaluate the corresponding responses
% for each of the three computational models created:
YmFile = uq_evalModel(myModel_mFile,X);
YmHandle = uq_evalModel(myModel_mHandle,X);
YmString = uq_evalModel(myModel_mString,X);

%%
% It can be observed that the results are identical
Diff_MFileMHandle = max(abs(diff(YmFile(:)-YmHandle(:))))
Diff_MFileMString = max(abs(diff(YmFile(:)-YmString(:))))

%%
% To visually show that the responses are indeed identical, 
% create a histogram of the responses from the different models:
myColors = uq_colorOrder(3);

uq_figure
uq_histogram(YmFile, 'FaceColor', myColors(1,:))
title('mFile')
xlabel('$\mathrm{Y}$')
ylabel('Frequency')

uq_figure
uq_histogram(YmHandle, 'FaceColor', myColors(2,:))
title('mHandle')
xlabel('$\mathrm{Y}$')
ylabel('Frequency')

uq_figure
uq_histogram(YmString, 'FaceColor', myColors(3,:))
title('mString')
xlabel('$\mathrm{Y}$')
ylabel('Frequency')
