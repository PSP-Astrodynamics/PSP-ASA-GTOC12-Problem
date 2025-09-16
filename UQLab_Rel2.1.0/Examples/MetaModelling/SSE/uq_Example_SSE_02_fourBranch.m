%% SSE METAMODELING: Four-branch function
%
% This example showcases how SSE approximates a function belonging to $C^0$,
% i.e., continuous functions that are not differentiable everywhere.
% Particularly, we will consider here a function that is common in the 
% reliability literature: the four-branch function. We compare an approach 
% with a static and sequential experimental design and investigate how the 
% sequential partitioning algorithm partitions the input space.

%% 1 - INITIALIZE UQLAB
%
% Clear all variables from the workspace, set the random number generator
% for reproducible results, and initialize the UQLab framework:
clearvars
rng(100,'twister')
uqlab

%% 2 - COMPUTATIONAL MODEL
%
% We use the analytical four-branch function from Schueremans et al. (2005) that 
% is commonly used in the reliability literature to simulate a series 
% system with four distinct limit states. 
% 
% $$\mathcal{M}(\mathbf{X}) = \min\left\{
% \begin{array}{l}
%   3 + 0.1(X_1-X_2)^2 - \frac{X_1+X_2}{\sqrt{2}},\\
%   3 + 0.1(X_1-X_2)^2 + \frac{X_1+X_2}{\sqrt{2}},\\
%   X_1-X_2 + \frac{6}{\sqrt{2}},\\
%   X_2-X_1 + \frac{6}{\sqrt{2}}.
% \end{array}
% \right\}
% $$
%
% This function is implemented in the function |uq_fourbranch(X)| supplied 
% with UQLab. The input parameters of this function are gathered 
% into the vector |X|.
% 
% Create a MODEL from the function file:
ModelOpts.mFile = 'uq_fourbranch';
myModel = uq_createModel(ModelOpts);

%% 3 - PROBABILISTIC INPUT MODEL
%
% The probabilistic input model are two independent random variables $X_1$ 
% and $X_2$ that follow a standard Gaussian distribution:
%
% $$X_1, X_2 \sim \mathcal{N}(0,1)$$
% 
%%
% Specify these marginals in UQLab:
for ii = 1:2
    InputOpts.Marginals(ii).Type = 'Gaussian';
    InputOpts.Marginals(ii).Parameters = [0 1];
end

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
% Set the expansion options to a degree-adaptive PCE with $p\in\{0,1,2\}$
MetaOpts.ExpOptions.MetaType = 'PCE';
MetaOpts.ExpOptions.Degree = 0:2;

%% 4.3 - Static experimental design
%
% SSE can sample the experimental design statically, before construction.
% In this case, the experimental design is sampled purely based on the
% input distribution.

%% 
% Place |NSamples| sample points in the input space. 
MetaOpts.ExpDesign.Sampling = 'LHS';
MetaOpts.ExpDesign.NSamples = 200;

%%
% Modify |NExp| to increase the number of refinement steps.
MetaOpts.Refine.NExp = 5;

%%
% Create the static experimental design-based SSE metamodel:
mySSE_static = uq_createModel(MetaOpts);

%% 
% Create a visual representation of the constructed SSE metamodel:
myFigure_static = uq_display(mySSE_static, 1, 'partitionPhysical', inf);

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
% Also modify |NExp| to allow for further partitioning, even after
% the |NSamples| have been added to the experimental design.
MetaOpts.Refine.NExp = 5;

%%
% Create the sequential experimental design-based SSE metamodel:
mySSE_sequential = uq_createModel(MetaOpts);

%% 
% Create a visual representation of the constructed SSE metamodel:
myFigure_sequential = uq_display(mySSE_sequential, 1, 'partitionPhysical', inf);

%%
%
% It can be clearly seen from the _Partition physical space_ plot that the
% algorithm partitions the input space such that the created domains
% cluster around the non-smooth regions of the input space, i.e. the
% boundaries of the individual limit-states. 

%% 5 - VALIDATION ERROR
%
% Compute the accuracy of created metamodels by means of a validation error.

%%
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
% Store in |YContainer| container:
YContainer = {YSSE_static, YSSE_sequential};

%% 5.1 - Computation of the validation error
mySSEs = {mySSE_static, mySSE_sequential};
methodLabels = {'SSE static ED', 'SSE sequential ED'};

fprintf('Validation error:\n')
fprintf('%20s | Rel. error | ED size\n', 'Method')
fprintf('--------------------------------------------\n')
for ii = 1:length(YContainer)
    normEmpErr = mean((Yval - YContainer{ii}).^2)/var(Yval);
    fprintf('%20s | %10.2e | %7d\n', methodLabels{ii}, normEmpErr, mySSEs{ii}.ExpDesign.NSamples);
end

%% 5.2 - Comparison of the results
%
% To visually assess the performance of each metamodel, produce scatter
% plots of the metamodel vs. the true response on the validation set:
uq_figure('Name', 'Metamodels vs. true model')

for ii = 1:length(YContainer)
    subplot(1,length(YContainer),ii)
    uq_plot(Yval, YContainer{ii}, '+')
    hold on
    uq_plot([min(Yval) max(Yval)], [min(Yval) max(Yval)], 'k')
    hold off
    axis equal 
    axis([min(Yval) max(Yval) min(Yval) max(Yval)]) 
    
    title(methodLabels{ii})
    xlabel('$\mathrm{Y_{true}}$')
    if strcmpi(methodLabels{ii},'PCE')
        ylabel('$\mathrm{Y_{PCE}}$')
    else
        ylabel('$\mathrm{Y_{SSE}}$')
    end
end

%%
%
% In the present example, the discontinuities of the target model are
% evenly distributed in the input space. The sequential enrichment does
% therefore only delivers slight gains in terms of improved approximation
% accuracy for the same experimental design size.

%% 6 - PARTITIONING OF THE INPUT SPACE
%
% We will now investigate how the static and sequential SSE partitioned the
% input space, depending on the discontinuities of the four-branch
% function.

%% 
%
% Plot individual limit-state boundaries. To this end, we evaluate 
% |uq_fourbranch_separate|, a special four-branch function that returns all
% limit states of |uq_fourbranch| seperately.
YSeperate = uq_fourbranch_separate(Xval);

%%
%
% Add the individual limit states to the previously generated SSE
% 'Partition physical space' plots.
ax_static = myFigure_static{1}.Children;
ax_sequential = myFigure_sequential{1}.Children;
myAxes = {ax_static, ax_sequential};

NLimits = size(YSeperate, 2);
myColors = uq_colorOrder(NLimits);
axTitles = {'Partition physical space - static experimental design', 'Partition physical space - sequential experimental design'};

for aa = 1:length(myAxes)
    ax = myAxes{aa};
    % activate ax
    hold(ax, 'on')
    for ii = 1:NLimits
        currPoints = YSeperate(:,ii) == Yval;
        % get boundary around points
        currX = Xval(currPoints,:);
        boundaryPoints = boundary(currX(:,1), currX(:,2));
        fill(ax, currX(boundaryPoints,1), currX(boundaryPoints,2),myColors(ii,:),'EdgeColor','none','FaceAlpha',0.5)
    end    
    % reorder plots
    ax.Children = [ax.Children(NLimits+1:end);ax.Children(1:NLimits)];
    title(ax, axTitles{aa})
end

%%
%
% For the sequential experimental design case, the input space partition 
% and the experimental design clearly cluster around the borders of the 
% limit states.

%%
% *References*
%
% * Schueremans, L., Van Gemert, D., Benefit of  splines and neural 
%   networks in simulation based structural reliability analysis, 
%   Structural Safety, 27(3):246–261(2005). 
%   DOI: <https://doi.org/10.1016/j.strusafe.2004.11.001 10.1016/j.strusafe.2004.11.001>