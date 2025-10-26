%% PC-KRIGING METAMODELING: DEMONSTRATION OF BASIC USAGE
%
% This example illustrates different options of constructing
% polynomial chaos-Kriging (PC-Kriging) metamodels of a simple
% one-dimensional analytical function.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(101,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL
%
% The computational model is a simple analytical function defined by:
%
% $$Y(x) = x \sin(x), \; x \in [0, 15]$$
% 
% Specify this model in UQLab using a string:
ModelOpts.mString = 'X.*sin(X)';
ModelOpts.isVectorized = true;

myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of one uniform random variable:
% 
% $X \sim \mathcal{U}(0, 15)$
%
% Specify the marginal and create a UQLab INPUT object:
InputOpts.Marginals.Type = 'Uniform';
InputOpts.Marginals.Parameters = [0 15];

myInput = uq_createInput(InputOpts);

%% 4 - EXPERIMENTAL DESIGN
%
% To compare different PC-Kriging metamodeling techniques, create an 
% experimental design of size $10$ using the Sobol' sequences:
X = uq_getSample(10,'Sobol');

%%
% Evaluate the computational model at the experimental design points:
Y = uq_evalModel(myModel,X);

%% 5 - PC-KRIGING METAMODELS
%
% Two different modes of PC-Kriging metamodel are considered below:
% Sequential mode and Optimal mode.

%% 5.1 Sequential PC-Kriging metamodel
%
% Select |PCK| as the metamodeling tool in UQLab
% and |sequential| as its mode:
SeqPCKOpts.Type = 'Metamodel';
SeqPCKOpts.MetaType = 'PCK';
SeqPCKOpts.Mode = 'sequential';

%%
% Assign the experimental design to the metamodel specification:
SeqPCKOpts.ExpDesign.X = X;
SeqPCKOpts.ExpDesign.Y = Y;

%%
% Specify the range for the selection of the maximum polynomial degree
% of the trend:
SeqPCKOpts.PCE.Degree = 1:10;

%%
% Create the Sequential PC-Kriging metamodel:
mySeqPCK = uq_createModel(SeqPCKOpts);

%%
% Print a summary of the resulting metamodel:
uq_print(mySeqPCK)

%%
% Display a visual representation of the resulting Sequential PC-Kriging
% metamodel:
uq_display(mySeqPCK)

%%
% The metamodel can predict at any new point in the input domain.
% For example, at $x = 3$:
[ySPCK,ySPCKs2] = uq_evalModel(mySeqPCK,3);
fprintf('Prediction mean value: %5.4e\n', ySPCK)
fprintf('Prediction variance:   %5.4e\n', ySPCKs2)

%% 5.2 Optimal PC-Kriging metamodel
%
% Optimal PC-Kriging metamodels differ from the Sequential PC-Kriging 
% metamodels only in the construction of the trend function.
% Hence, the same options as before can be used with a slight adjustment,
% now with |optimal| as the mode:
OptPCKOpts = SeqPCKOpts;
OptPCKOpts.Mode = 'optimal';

%%
% Create the Optimal PC-Kriging metamodel:
myOptPCK = uq_createModel(OptPCKOpts);

%%
% Display a visual representation of the resulting Optimal PC-Kriging
% metamodel:
uq_display(myOptPCK)
