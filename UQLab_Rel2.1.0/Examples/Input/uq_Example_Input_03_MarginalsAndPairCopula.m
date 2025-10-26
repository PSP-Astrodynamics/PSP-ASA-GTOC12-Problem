%% INPUT MODULE: MARGINALS AND PAIR COPULA
%
% This example showcases how to define a probabilistic input model with 
% a pair copula dependence structure.
% In order to display the copula density, the marginals are kept as uniform
% distributions in $[0,1]$.
% In this way, the joint probabilty density function (PDF) and the copula
% density are equivalent.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace 
% and initialize the UQLab framework:
clearvars
uqlab

%% 2 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of two variables:

%%
% $X_1 \sim \mathcal{U}(0,1)$
InputOpts.Marginals(1).Type = 'Uniform';
InputOpts.Marginals(1).Parameters = [0 1];

%%
% $X_2 \sim \mathcal{U}(0,1)$
InputOpts.Marginals(2).Type = 'Uniform';
InputOpts.Marginals(2).Parameters = [0 1];

%%
% Define the copula between the two variables as a Gumbel pair copula:
%
% $C_{12} = \textrm{Gumbel}(1.2)$
InputOpts.Copula.Type = 'Pair';
InputOpts.Copula.Family = 'Gumbel';
InputOpts.Copula.Parameters = 1.5;

%%
% Create an INPUT object based on the specified marginals and copula:
myInput = uq_createInput(InputOpts);

%%
% Print a report of the INPUT object:
uq_print(myInput)

%%
% Display a visualization of the INPUT object:
uq_display(myInput)

%%
% Alternatively, the copula of the input model can be specified using
% the function |uq_PairCopula(Type, Parameters, Rotation)| as follows:
InputOpts.Copula = uq_PairCopula('Gumbel',1.5);

%%
% Create the INPUT object:
myInput2 = uq_createInput(InputOpts);

%%
% Display a visualization of the INPUT object:
uq_display(myInput2)

%% 3 - DEPENDENCE PROPERTIES OF THE INPUT MODEL
%
% The dependence properties of the input model are fully determined
% by the input copula. 
%
% For instance, a popular measure of the global dependence between two
% random variables is their Kendall's tau, defined as the probability that
% two realizations from the random variables are concordant minus the
% probability that they are discordant.

Tau_K = uq_PairCopulaKendallTau(myInput.Copula)

%%
% The probability of joint extremes is also of interest, for instance in
% reliability and fragility analysis.
% The Gumbel copula defined above models the upper tail dependence,
% that is, a positive probability $\lambda_u$ that the random variables
% it couples take jointly high values:
Lambda_U = uq_PairCopulaUpperTailDep(myInput.Copula)

%%
% This makes the Gumbel copula different from the Gaussian copula,
% which instead never assigns upper or lower tail dependence,
% even for high values of its correlation parameter:

GaussianCopula = uq_PairCopula('Gaussian',0.99);
Lambda_U_Gaussian = uq_PairCopulaUpperTailDep(GaussianCopula)

%%
% Different parametric pair copula families have different dependence
% properties (Kendall's tau, upper/lower tail dependence).
% These properties should be considered when deciding which pair copula to
% use to model the input!
% For summary, refer to the UQLab's Input Manual, Chapter "Theory".

%% 4 - COPULA ROTATION 
%
% The PDF of a copula distribution can be rotated by $90$, $180$, or $270$
% degrees to model different types of dependencies.
% For instance:
InputOpts.Copula = uq_PairCopula('Gumbel', 1.5, 180);
%%
% creates a version of the Gumbel copula rotated by $180$ degrees. 
% Mathematically, this is obtained by flipping the original copula 
% density $c(u,v)$ around both axes:
% $c_{180}(u,v) = c(1-u,1-v)$.

%%
% Create an INPUT object based on the rotated copula:
myInput_rot180 = uq_createInput(InputOpts);

%%
% Display a visualization of the object:
uq_display(myInput_rot180)

%%
% This new copula has different dependence properties.
% For instance, it has no upper tail dependence anymore:
UpperTailDep = uq_PairCopulaUpperTailDep(myInput_rot180.Copula)

%%
% but has lower tail one:
LowerTailDep = uq_PairCopulaLowerTailDep(myInput_rot180.Copula) 

%%
% Analogously, the copula PDF can be rotated by $90$ and $270$ degrees:
InputOpts.Copula = uq_PairCopula('Gumbel', 1.5, 90);
myInput_rot90 = uq_createInput(InputOpts);

uq_display(myInput_rot90)

%%
InputOpts.Copula = uq_PairCopula('Gumbel', 1.5, 270);
myInput_rot270 = uq_createInput(InputOpts);

uq_display(myInput_rot270)
