%% SSE METAMODELING: Corner function
%
% This example showcases how SSE approximates a function with quasi-compact
% support, i.e., a function that is almost zero in a majority of the input
% space and non-zero only in a small subdomain of the input space.
% Particularly, we will consider here the corner function. We compare an 
% approach with a static and sequential experimental design and investigate
% how the sequential partitioning algorithm partitions the input space.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL
%
% We use the analytical 2D corner function from Genz (1984) in an 
% implementation from <https://www.sfu.ca/~ssurjano/copeak.html www.sfu.ca>            
% that is commonly used to test integration algorithms. 
% 
% $$\mathcal{M}(\mathbf{X}) = \left(1+\sum_{i=1}^2 a x_i\right)^{-3},$$
% 
% with the shape parameter $a=5$. This function is implemented in the 
% function |uq_copeak(X)| supplied with UQLab. The input parameters of this
% function are gathered into the vector |X|.
% 
% Create a MODEL from the function file:
ModelOpts.mFile = 'uq_copeak';
ModelOpts.isVectorized = true;
myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model are two independent random variables $X_1$ 
% and $X_2$ that follow a standard Uniform distribution:
%
% $$X_1, X_2 \sim \mathcal{U}(0,1)$$
% 
%%
% Specify these marginals in UQLab:
InputOpts.Marginals(1).Type = 'Uniform';
InputOpts.Marginals(1).Parameters = [0 1];
InputOpts.Marginals(2).Type = 'Uniform';
InputOpts.Marginals(2).Parameters = [0 1];

%%
% Create an INPUT object based on the specified marginals:
myInput = uq_createInput(InputOpts);

%% 4 - STOCHASTIC SPECTRAL EMBEDDING (SSE) METAMODELS
%
% This section showcases two ways to calculate the stochastic spectral 
% embedding (SSE) metamodel.

%%
% Select SSE as the metamodeling tool in UQLab:
MetaOpts.Type = 'Metamodel';
MetaOpts.MetaType = 'SSE';

%% 4.1 - Assign full model
%
% Assign the full model to |MetaOpts|:
MetaOpts.FullModel = myModel;

%% 4.2 - Residual expansion
%
% For the residual expansions of the SSE metamodel, we choose 
% degree-adaptive polynomial chaos expansions.

%%
% set the expansion options to a degree-adaptive PCE with
% $p\in\{0,1,2\}$:
MetaOpts.ExpOptions.MetaType = 'PCE';
MetaOpts.ExpOptions.Degree = 0:2;

%% 4.3 - Static experimental design
%
% SSE can sample the experimental design statically, before construction.
% In this case, the experimental design is sampled purely based on the
% input distribution.

%% 
% Place |NSamples| sample points in the input space: 
MetaOpts.ExpDesign.Sampling = 'LHS';
MetaOpts.ExpDesign.NSamples = 100;

%%
% Modify |NExp| to increase the number of refinement steps:
MetaOpts.Refine.NExp = 5;

%%
% Create the static experimental design-based SSE metamodel:
mySSE_static = uq_createModel(MetaOpts);

%% 4.4 - Sequential experimental design
%
% SSE can automatically place the experimental design in the created 
% subdomains by evaluating the full model. This typically leads to more
% informative full model evaluations.

%% 
% Sequentially place |NEnrich| sample points in the created subdomains, 
% until the total experimental design has a size of |NSamples|. 
MetaOpts.ExpDesign.Sampling = 'Sequential';
MetaOpts.ExpDesign.NEnrich = 5;

%%
% Modify |NExp| to allow for further partitioning, even after
% the |NSamples| have been added to the experimental design.
MetaOpts.Refine.NExp = 5;

%%
% Create the sequential experimental design-based SSE metamodel:
mySSE_sequential = uq_createModel(MetaOpts);

%% 5 - VALIDATION ERROR
%
% Compute the accuracy of the created metamodels by means of a validation error.

%%
%
% Create a validation sample of size $10^4$ from the input model:
Xval = uq_getSample(1e4);

%%
% Evaluate the full model response at the validation sample points:
Yval = uq_evalModel(myModel,Xval);

%%
% Evaluate the corresponding responses for each of the SSE metamodels 
% created before:
YSSE_static = uq_evalModel(mySSE_static,Xval);
YSSE_sequential = uq_evalModel(mySSE_sequential,Xval);

%%
% Store in |YSSE| container:
YSSE = {YSSE_static, YSSE_sequential};

%% 5.1 - Computation of the validation error
mySSEs = {mySSE_static, mySSE_sequential};
methodLabels = {'SSE static ED', 'SSE sequential ED'};

fprintf('Validation error:\n')
fprintf('%20s | Rel. error | ED size\n', 'Method')
fprintf('--------------------------------------------\n')
for ii = 1:length(YSSE)
    normEmpErr = mean((Yval - YSSE{ii}).^2)/var(Yval);
    fprintf('%20s | %10.2e | %7d\n', methodLabels{ii}, normEmpErr, mySSEs{ii}.ExpDesign.NSamples);
end

%%
%
% The validation error is orders of magnitude smaller when using the sequential
% experimental design.

%% 6 - PARTITIONING OF THE INPUT SPACE
%
% We will now compare the input space partitioning.

%%
% Run the |uq_display| function for static and sequential experimental
% design SSE metamodels
uq_display(mySSE_static, 1, 'partitionPhysical', inf)
title('Partitioning physical space - static experimental design')
uq_display(mySSE_sequential, 1, 'partitionPhysical', inf)
title('Partitioning physical space - sequential experimental design')

%%
%
% The sequential placement of experimental designs allows a more targeted
% spending of the computational budget. In the case of the corner-peak
% function the experimental design and subdomains clearly cluster around
% the peak in the lower left corner, i.e., $\mathbf{x}=(0, 0)$.

%%
% *References*
%
% * Genz, A., Testing multidimensional integration routines, 
%   Proceedings of international conference on tools, methods and languages 
%   for scientific and engineering computation, 81–94 (1984). 