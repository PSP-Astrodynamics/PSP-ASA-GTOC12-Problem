function mergedPCE = uq_SSE_mergePCEToChild(parentPCE, child)
% OBJ = UQ_SSE_MERGEPCETOCHILD(PARENTPCE, CHILD): Merges PARENTPCE to CHILD
%     with two different behaviours:
%
%     IF CHILD is a PCE:
%     Returns as MERGED PCE the sum of the CHILD PCE and the PARENTPCE in
%     the CHILD PCE domain
%
%     IF CHILD are domain bounds:
%     Expresses the PARENT PCE in the truncated domain bounds CHILD.

if isa(child, 'uq_model') && strcmpi(child.Type, 'uq_metamodel') && strcmpi(child.Options.MetaType, 'PCE')
    % child is a PCE
    childPCE = child;
    % project parent onto child
    [BASIS,COEFFICIENTS] = efficientProjection(parentPCE,childPCE.Internal.Input);

    % Add childPCE to BASIS and COEFFICIENTS
    relevIDs = abs(childPCE.PCE.Coefficients) > 0;
    childBasis = childPCE.PCE.Basis.Indices(relevIDs,:);
    childCoefficients = childPCE.PCE.Coefficients(relevIDs);
    
    % sort basis
    [childBasis, idSort] = sortrows(childBasis);
    childCoefficients = childCoefficients(idSort);
    
    % check if basis exists and extend or add
    matchedIndices_full = ismember(BASIS,childBasis,'rows');
    matchedIndices_child = ismember(childBasis,BASIS,'rows');

    % add existing basis coefficients
    COEFFICIENTS(matchedIndices_full) = ...
        COEFFICIENTS(matchedIndices_full) + childCoefficients(matchedIndices_child);

    % create new basis entries for non-existing bases
    BASIS = [BASIS; childBasis(~matchedIndices_child,:)];
    COEFFICIENTS = [COEFFICIENTS; childCoefficients(~matchedIndices_child)];
    
    % prepare mergedPCEOpts
    mergedPCEOpts.Input = childPCE.Internal.Input;
    mergedPCEOpts.PCE.Basis.PolyTypes = childPCE.PCE.Basis.PolyTypes;
elseif isnumeric(child) 
    % child PCE are bounds, truncate distribution
    childBounds = child;
    % remove bounds and get currBounds X
    parentMarginals = parentPCE.Internal.Input.Marginals;
    if isfield(parentMarginals,'Bounds')
        % remove bounds field
        parentMarginals = rmfield(parentMarginals,'Bounds');
    end
    currBounds_X = uq_all_invcdf(childBounds,parentMarginals);
    metaOptsCurr.Input = uq_SSE_truncateDist(parentPCE.Internal.Input, currBounds_X);
    
    % project
    [BASIS,COEFFICIENTS] = efficientProjection(parentPCE,metaOptsCurr.Input);
    
    % prepare mergedPCEOpts
    mergedPCEOpts.Input = metaOptsCurr.Input;
    mergedPCEOpts.PCE.Basis.PolyTypes = repmat({'arbitrary'},1,size(childBounds,2));
else
    error('Wrong CHILD type')
end

% Create new predictor with BASIS and COEFFICIENTS
mergedPCEOpts.Type = 'Metamodel';
mergedPCEOpts.MetaType = 'PCE';
mergedPCEOpts.Method = 'Custom';

% assign BASIS and COEFFICIENTS
mergedPCEOpts.PCE.Basis.Indices = BASIS;
mergedPCEOpts.PCE.Coefficients = COEFFICIENTS;

% create mergedPCE
mergedPCE = uq_createModel(mergedPCEOpts,'-private');
end

%% UTILITY FUNCTIONS
function [BASIS,COEFFICIENTS] = efficientProjection(parentPCE,childInput)
% efficient projection for PCEs with sparse interaction
% init
metaOptsCurr.Type = 'Metamodel';
metaOptsCurr.MetaType = 'PCE';
metaOptsCurr.Method = 'Quadrature';%'LARS';
metaOptsCurr.Display = 0; %turn off diplay
metaOptsCurr.Input = childInput;

% get parent basis
relevIDs = abs(parentPCE.PCE.Coefficients) > 0;
parentInput = parentPCE.Internal.Input;
parentBasis = parentPCE.PCE.Basis.Indices(relevIDs,:);
parentCoeffs = parentPCE.PCE.Coefficients(relevIDs,:);

% get rid of constant polynomial
constID = sum(parentBasis,2) == 0;

% init dummy PCE
rowPCEOpts.Type = 'Metamodel';
rowPCEOpts.MetaType = 'PCE';
rowPCEOpts.Method = 'Custom';

% loop over basis rows and project down to childPCE
if any(constID)
    % init with constant poly
    BASIS = parentBasis(constID,:);
    COEFFICIENTS = parentCoeffs(constID);
    parentBasis = parentBasis(~constID,:);
    parentCoeffs = parentCoeffs(~constID);
else
    BASIS = [];
    COEFFICIENTS = [];
end

% precompute arbitrary basis for performance
% parent
PrecompParent.PolyTypes = repmat({'arbitraryPrecomp'},1,size(parentBasis,2));
maxDegree = max(sum(parentBasis,2));
for ii = 1:size(parentBasis,2)
    % check if current marginal is arbitrary
    if strcmpi(parentPCE.PCE.Basis.PolyTypes,'arbitrary')
        % if arbitrary
        PrecompParent.PolyTypes{ii} = 'arbitraryPrecomp';
        % get marginal and precompute
        MarginalCurr = parentPCE.Internal.Input.Marginals(ii);
        [PrecompParent.PolyTypesAB{ii}, PrecompParent.PolyCustom{ii}] = ...
            uq_PCE_initialize_arbitrary_basis(MarginalCurr,'stieltjes','polynomials',maxDegree+1);
    else
        % not arbitrary
        PrecompParent.PolyTypes{ii} = parentPCE.PCE.Basis.PolyTypes{ii};
        PrecompParent.PolyTypesAB{ii} = parentPCE.PCE.Basis.PolyTypesAB{ii};
        PrecompParent.PolyCustom{ii} = [];
    end
end

% child
PrecompChild.PolyTypes = repmat({'arbitraryPrecomp'},1,size(parentBasis,2));
maxDegree = max(sum(parentBasis,2));
for ii = 1:size(parentBasis,2)
    % extract current marginal
    MarginalCurr = childInput.Marginals(ii);
    % arbitrary
    PrecompChild.PolyTypes{ii} = 'arbitraryPrecomp';
    % precompute
    [PrecompChild.PolyTypesAB{ii}, PrecompChild.PolyCustom{ii}] = ...
        uq_PCE_initialize_arbitrary_basis(MarginalCurr,'stieltjes','polynomials',maxDegree+1);
end

for ii = 1:size(parentBasis,1)
    % get curr subBasis
    currBasis = parentBasis(ii,:);
    currCoeff = parentCoeffs(ii);
    nonConst = currBasis > 0;
    nonConstId = find(nonConst);

    % create dummy PCE input
    rowPCEInputOpts_parent.Marginals = parentPCE.Internal.Input.Options.Marginals(nonConst);
    rowPCEOpts.Input = uq_createInput(rowPCEInputOpts_parent,'-private');
    
    % create row PCE
    for kk = 1:sum(nonConst)
        rowPCEOpts.PolyTypesAB{kk} = PrecompParent.PolyTypesAB{nonConstId(kk)};
        rowPCEOpts.PolyCustom{kk} = PrecompParent.PolyCustom{nonConstId(kk)};
    end
    rowPCEOpts.PCE.Basis.PolyTypes = PrecompParent.PolyTypes(nonConst);
    rowPCEOpts.PCE.Basis.Indices = currBasis(nonConst);
    rowPCEOpts.PCE.Coefficients = currCoeff;
    myRowPCE_parent = uq_createModel(rowPCEOpts,'-private');

    % create child dummy input
    rowPCEInputOpts_child.Marginals = childInput.Options.Marginals(nonConst);
    metaOptsCurr.Input = uq_createInput(rowPCEInputOpts_child,'-private');

    % project down to childPCE
    metaOptsCurr.Degree = sum(currBasis); % ATTENTION, use sum
    metaOptsCurr.FullModel = myRowPCE_parent;
    for kk = 1:sum(nonConst)
        metaOptsCurr.PolyTypesAB{kk} = PrecompChild.PolyTypesAB{nonConstId(kk)};
        metaOptsCurr.PolyCustom{kk} = PrecompChild.PolyCustom{nonConstId(kk)};
    end
    metaOptsCurr.PolyTypes = PrecompChild.PolyTypes(nonConst);
    myRowPCE_child = uq_createModel(metaOptsCurr,'-private');
   
    % store resulting 
    relevIDs = abs(myRowPCE_child.PCE.Coefficients) > 0;
    childCoefficients = myRowPCE_child.PCE.Coefficients(relevIDs);
    childBasis = myRowPCE_child.PCE.Basis.Indices(relevIDs,:);
    childBasis_full = zeros(size(childBasis,1),size(currBasis,2));
    childBasis_full(:,nonConst) = childBasis;
    
    % sort basis
    [childBasis_full, idSort] = sortrows(childBasis_full);
    childCoefficients = childCoefficients(idSort);
    
    % check if basis exists and extend or add
    if ~isempty(BASIS)
        % BASIS is not empty
        matchedIndices_full = ismember(BASIS,childBasis_full,'rows');
        matchedIndices_child = ismember(childBasis_full,BASIS,'rows');

        % add existing basis coefficients
        COEFFICIENTS(matchedIndices_full) = ...
            COEFFICIENTS(matchedIndices_full) + childCoefficients(matchedIndices_child);

        % create new basis entries for non-existing bases
        BASIS = [BASIS; childBasis_full(~matchedIndices_child,:)];
        COEFFICIENTS = [COEFFICIENTS; childCoefficients(~matchedIndices_child)];
        
        % sort
        [BASIS, idSort] = sortrows(BASIS);
        COEFFICIENTS = COEFFICIENTS(idSort);
    else
        % BASIS is empty - use child
        BASIS = childBasis_full;
        COEFFICIENTS = childCoefficients;
    end
end
end