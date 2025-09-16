%% SENSITIVITY: SOBOL' INDICES OF A HIGH-DIMENSIONAL FUNCTION
%
% In this example, the first- and second-order Sobol' sensitivity indices
% for a high-dimensional ($M = 100$) non-linear analytical function are
% calculated by means of polynomial chaos expansion (PCE).
% 
% *Note*: This example runs a very high-dimensional analysis,
% it may take up between 2 to 3 minutes to complete.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL
%
% The high-dimensional function presented in this example is a non-linear
% arbitrary dimensional function (with input dimension $M >= 55$)
% defined as:
%
% $$Y = 3 - \frac{5}{M} \sum_{k = 1}^{M} k x_k +
% \frac{1}{M}\sum_{k = 1}^{M} k x_k^3  + 
% \frac{1}{3M}\sum_{k = 1}^{M} k \ln\left(x_k^2 + x_k^4\right) 
% + x_1 x_2^2  + x_2 x_4 - x_3 x_5 + x_{51} + x_{50}x_{54}^2$$
% 
% If all the input variables are identically distributed,
% the sensitivity pattern of this function has an overall 
% non-linearly increasing trend with the variable number.
% It also presents distinct peaks for variables $x_2$, $x_{20}$, $x_{51}$,
% and $x_{54}$.
% Furthermore, four 2-term interaction peaks are expected: 
% $x_1 x_2$, $x_2 x_4$, $x_3 x_5$, and $x_{50} x_{54}$. 
% Finally, by construction, the two pairs of interaction terms
% $x_1 x_2$, $x_{50} x_{54}$ and $x_2 x_4$, $x_{3} x_{5}$ 
% are expected to have identical sensitivity indices, respectively.
%
% This computation is carried out by the function
% |uq_many_inputs_model(X)| supplied with UQLab.
% The input parameters of this function are gathered into the vector |X|.

%% 
% Create a MODEL object from the function file:
ModelOpts.mFile = 'uq_many_inputs_model';

myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model consists of $100$ uniformly distributed 
% random variables: 
%
% $$X_i \sim \mathcal{U}(1,2) \quad i = 1,\ldots,100, \; i \neq 20,$$
%
% $$X_{20} \sim \mathcal{U}(1,3)$$
%
% Specify the marginals of the input model:
M = 100;
for ii = 1:M
    InputOpts.Marginals(ii).Type = 'Uniform';
    if ii == 20
        InputOpts.Marginals(ii).Parameters = [1 3];
    else
        InputOpts.Marginals(ii).Parameters = [1 2];
    end
end
%%
% Create an INPUT object based on the marginals:
myInput = uq_createInput(InputOpts);

%% 4 - SENSITIVITY ANALYSIS
%
% Due to the high dimensionality of the model,
% the Sobol' indices are directly calculated
% with polynomial chaos expansion (PCE).

%% 4.1 Create a PCE of the full model
%
% Select |PCE| as the metamodeling tool in UQLab:
PCEOpts.Type = 'Metamodel';
PCEOpts.MetaType = 'PCE';

%%
% Specify the computational model to create an experimental design:
PCEOpts.FullModel = myModel;

%%
% Specify degree-adaptive PCE (*default*: sparse PCE):
PCEOpts.Degree = 1:4;

%%
% Specify the parameters for the PCE truncation scheme:
PCEOpts.TruncOptions.qNorm = 0.7;
PCEOpts.TruncOptions.MaxInteraction = 2;

%%
% Specify an experimental design of size $1'200$
% based on the latin hypercube sampling (LHS):
PCEOpts.ExpDesign.NSamples = 1200;
PCEOpts.ExpDesign.Sampling = 'LHS';

%% 
% Create the PCE metamodel:
myPCE = uq_createModel(PCEOpts);

%% 4.2 Sensitivity analysis of the PCE metamodel
%
% The sensitivity module automatically calculates the sensitivity indices
% from the PCE coefficients if the current model is a PCE metamodel.

%%
% Specify the sensitivity module and Sobol' indices:
SobolOpts.Type = 'Sensitivity';
SobolOpts.Method = 'Sobol';

%%
% Set the maximum Sobol' indices order:
SobolOpts.Sobol.Order = 2;

%%
% Run the sensitivity analysis:
mySobolAnalysisPCE = uq_createAnalysis(SobolOpts);

%% 5 - RESULTS VISUALIZATION
%
% Display a graphical representation of the results:
uq_display(mySobolAnalysisPCE)
