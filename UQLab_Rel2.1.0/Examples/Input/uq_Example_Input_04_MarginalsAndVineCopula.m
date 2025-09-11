%% INPUT MODULE: MARGINALS AND VINE COPULA
%
% This example showcases how to define a probabilistic input model in three
% dimension or higher with a vine copula dependence structure.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace 
% and initialize the UQLab framework:
clearvars
uqlab

%% 2 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of three variables:
%
% * $X_1 \sim \mathcal{N}(0,1)$
% * $X_2 \sim \mathcal{B}(1,3)$
% * $X_3 \sim \mathcal{Gumbel}(1,3)$

%%
% Specify the marginals of these variables:
InputOpts.Marginals(1).Type = 'Gaussian';
InputOpts.Marginals(1).Parameters = [0 1];
InputOpts.Marginals(2).Type = 'Beta';
InputOpts.Marginals(2).Parameters = [1 3];
InputOpts.Marginals(3).Type = 'Gumbel';
InputOpts.Marginals(3).Parameters = [1 3];

%%
% The variables are coupled by a Canonical Vine (CVine).
% A vine in dimension $M$ requires the specification of
% $M \cdot (M-1)/2$ pair copulas (here, there are three pair copulas):
InputOpts.Copula.Type = 'CVine';
InputOpts.Copula.Families = {'Gumbel', 'Gaussian', 'Frank'}; 
InputOpts.Copula.Parameters = {1.5, -0.4, [0.3]};
InputOpts.Copula.Rotations = [180 0 270];
InputOpts.Copula.Structure = 1:3;

%%
% Create an INPUT object based on the specified marginals and copula:
myInput = uq_createInput(InputOpts) ;

%% 3 - PRINT AND VISUALIZE THE INPUT
%
% Print a summary of the input model:
uq_print(myInput);

%% 
% Display a visualization of the input model:
uq_display(myInput)

%% 4 - HOW TO ASSIGN THE PAIR COPULAS IN THE VINE?
%
% The pair copulas composing the vine can be a difficult beast to tame. 
%
% Some (the first $M-1$ ones, for an input of dimension $M$) are
% unconditional pair copulas, the rest are conditional on other variables.
% But which variables do they couple?
% It all depends on the vine type and structure!
%
% If unsure, call the function |uq_CopulaSummary|:
% when fed with a vine copula type and a vine copula structure,
% it prints a report of the meaning of the pair copulas of that vine:
uq_CopulaSummary('CVine',1:3)

%%
% The same function, when fed with an actual copula,
% prints the same copula information as provided by |uq_print|:
uq_CopulaSummary(myInput.Copula);

%% 
% Furthermore, a visual representation of the pair copulas composition
% in a vine can be obtained using the |uq_drawVineCopula| function:
uq_drawVineCopula(myInput.Copula);

%% 5 - VINE TRUNCATION 
%
% Sometimes, due to lack of information,
% specifying conditional pair copulas in a vine may be hard or impossible.
% In these case, it may be reasonable to assume conditional independence 
% from a certain conditioning order.
% This is called _truncation_ of a vine. 
%
% For instance, truncating a vine at the 1st level means that only the 
% unconditional pair copulas are retained, and the rest are set to the 
% independence copula:
InputOpts.Copula.Truncation = 1;

%%
% Create an INPUT object based on the truncated vine copula:
myInput_Truncated = uq_createInput(InputOpts);

%%
% Print a summary of the input with truncated vine:
uq_print(myInput_Truncated)

%% 
% Display a visualization of the input model with truncated vine:
uq_display(myInput_Truncated)
