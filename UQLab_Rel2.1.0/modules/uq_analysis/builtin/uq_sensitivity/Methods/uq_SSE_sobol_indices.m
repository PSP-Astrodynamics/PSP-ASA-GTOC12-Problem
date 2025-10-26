function Results = uq_SSE_sobol_indices(max_order, CurrentModel)
% RESULTS = UQ_SSE_SOBOL_INDICES(MAX_ORDER,SSEMODEL): analytically calculate Sobol'
%     indices up to maximum order MAX_ORDER for the SSE model SSEMODEL.
%
% See also: UQ_SOBOL_INDICES, UQ_SENSITIVITY

%% RETRIEVE INFORMATION FROM THE PCE MODEL

% make sure the model is of "uq_metamodel" type.
if ~strcmp(CurrentModel.Type, 'uq_metamodel')
    error('Error, uq_getExpDesignSample is not defined for a model of type %s\n', CurrentModel.Type);
end

% Input/Output size, statistical moments of the PCE
Nout = CurrentModel.Internal.Runtime.Nout;
M = CurrentModel.Internal.Runtime.M;

% if no max_order is requested, we choose the maximum order of the polynomials
if ~exist('max_order', 'var')
    max_order = 2;
end

%% Analytical Sobol's sensitivity indices
%  Based on Marelli, 2021

% Work only on non-constant variables
nonConst = CurrentModel.Internal.Input.nonConst;

% Initialize the (cell) array containing the (total) Sobol indices.
sobol_cell_array = cell(max_order, 1) ;
total_sobol_array = zeros(length(nonConst),Nout) ;

% Initialize the cell to store the names of the variables of the Sobol Idx.
VarIdx = cell(max_order,1);
TotalVariance = zeros(1, Nout);

% loop over the output variables
for oo = 1:Nout
    % extract sse
    currSSE = CurrentModel.SSE(oo);

    % check if flattened
    if numnodes(currSSE.FlatGraph) == 0
        error('Only works with flat graph!')
    end

    %% Prepare
    % get terminal domain ids
    flatGraph = currSSE.FlatGraph;

    %% Compute expectation
    meanEst = 0;
    % loop over terminal domains
    for ii = 1:numnodes(flatGraph)
        currInputMass = flatGraph.Nodes.inputMass(ii);
        currPCE = flatGraph.Nodes.expansions{ii};

        % get constant polys coefficient
        a0 = currPCE.PCE.Coefficients(1);

        % add to mean
        meanEst = meanEst + a0*currInputMass;
    end
    % return
    CurrentModel.Internal.Sensitivity.sobol_indices.mu(oo) = meanEst;

    %% Compute Variance
    varEst = 0;
    % loop over terminal domains
    for ii = 1:numnodes(flatGraph)
        currInputMass = flatGraph.Nodes.inputMass(ii);
        currPCE = flatGraph.Nodes.expansions{ii};

        % get constant polys coefficient
        a = sum(currPCE.PCE.Coefficients(1:end).^2);

        % add to mean
        varEst = varEst + a*currInputMass;
    end
    % return
    TotalVariance = varEst - meanEst^2;
    CurrentModel.Internal.Sensitivity.sobol_indices.var(oo) = TotalVariance;

    %% Compute First order Sobol' indices
    PartialVariance = zeros(1,M);

    for currDim = 1:M
        % create graph to store hierarchy of local PCEs w.r.t. to subexpanion
        currSub = flatGraph;

        % loop over terminal domains
        for ii = 1:numnodes(currSub)
            % get current bounds
            currBounds = flatGraph.Nodes.bounds{ii}(:,currDim);

            % check if curr domain is subdomain or independent domain;
            % loop over stored domains
            for kk = 1:numnodes(currSub)
                if kk ~= ii
                    currStoredBounds = currSub.Nodes.bounds{kk}(:,currDim);
                    isParentDomain = ...
                        and(currStoredBounds(1) <= currBounds(1),currStoredBounds(2) >= currBounds(2));

                    % return
                    if isParentDomain
                        % check if edge has been added already from other side
                        if ~any(predecessors(currSub,kk) == ii)
                            % add connecting edge
                            currSub = addedge(currSub,kk,ii);
                        end
                    end
                end
            end
        end

        % loop over curr Sub domains and project
        % get terminal nodes
        termDoms = find(outdegree(currSub) == 0); ll = 1;
        for ii = termDoms'
            % child PCE
            childPCE = currSub.Nodes.expansions{ii};

            % integrate over ~dimCurr 
            currExtent = range(currSub.Nodes.bounds{ii});
            mySubExpansion_child = marginalizeOthers(childPCE,currExtent,currDim);

            % get previous domains
            prevDoms = predecessors(currSub,ii);

            % loop over previous domains and project onto ii
            for jj = prevDoms'
                % create subexpansion
                parentPCE = currSub.Nodes.expansions{jj};

                % create subexpansion
                currExtent = range(currSub.Nodes.bounds{jj});
                mySubExpansion_parent = marginalizeOthers(parentPCE,currExtent,currDim);

                % project onto child
                mySubExpansion_child = mergePCEs(mySubExpansion_child, mySubExpansion_parent);
            end

            % get the id vector to id the current dimension
            idVec = false(1,M); idVec(currDim) = true;

            % store sub expansion
            mySubExpansionContainer.PCE(ll) = mySubExpansion_child;
            mySubExpansionContainer.inputMass(ll) = prod(range(currSub.Nodes.bounds{ii}(:,idVec)));
            ll = ll + 1;
        end

        % compute partial variances
        % loop over subdomains
        for ii = 1:length(mySubExpansionContainer.PCE)
            % get input mass
            currInputMass = mySubExpansionContainer.inputMass(ii);

            % get coefficients
            a = sum(mySubExpansionContainer.PCE(ii).PCE.Coefficients.^2);

            % add to mean
            PartialVariance(currDim) = PartialVariance(currDim) + a*currInputMass;
        end

        % clean up
        clearvars mySubExpansionContainer
    end

    % return
    PartialVariance = PartialVariance - meanEst^2;
    CurrentModel.Internal.Sensitivity.sobol_indices.partialVar(oo,:) = PartialVariance;

    %% Compute indices
    % Only first-order implemented until now
    sobol_cell_array{1}(:, oo) = PartialVariance.'/TotalVariance;
end


%% assign the outputs
% find the non-constant variables
nonConstIdx = CurrentModel.Internal.Runtime.nonConstIdx;
CurrentModel.Internal.Sensitivity.VariableNames = {CurrentModel.Internal.Input.Marginals(nonConstIdx).Name};
CurrentModel.Internal.Sensitivity.sobol_indices.sobol_cell_array = sobol_cell_array;
if nargout > 0
    % Combine zero valued inputs (constant) with the computed ones
    Results.FirstOrder = zeros(M,Nout);
    
    Results.FirstOrder(nonConst,:) = sobol_cell_array{1};
    
    Results.VarIdx{1} = (1:M)';
     
    Results.TotalVariance = TotalVariance;    
    Results.VariableNames = {CurrentModel.Internal.Input.Marginals(nonConstIdx).Name};
    
    Results.AllOrders{1} = sobol_cell_array{1};
end

end


function marginalizedPCE = marginalizeOthers(fullPCE,extent,dim)
% marginalize over all but dim dimensions and create PCE

% initialize
marginalOpts.Type = 'Metamodel';
marginalOpts.MetaType = 'PCE';
marginalOpts.Method = 'Custom';
idVec = false(size(extent)); idVec(dim) = true;

% create Input
inputOpts.Marginals = fullPCE.Options.Input.Options.Marginals(dim);
inputMarginal = uq_createInput(inputOpts,'-private');

% and assign
marginalOpts.Input = inputMarginal;

% extract basis
currBasis = fullPCE.PCE.Basis.Indices;
relevIds = sum(currBasis,2) == currBasis(:,dim);
marginalOpts.PCE.Basis.PolyTypes = fullPCE.PCE.Basis.PolyTypes(dim);
marginalOpts.PCE.Basis.Indices = fullPCE.PCE.Basis.Indices(relevIds,dim);

% multiply coefficients with input mass from ~dim dimensions
currInputMass = prod(extent(~idVec));
marginalOpts.PCE.Coefficients = fullPCE.PCE.Coefficients(relevIds).*currInputMass;

% create subexpansion
marginalizedPCE = uq_createModel(marginalOpts,'-private');
end

function mergedPCE = mergePCEs(childPCE, parentPCE)
% merge two provided PCEs
% init
mergedOpts.Type = 'Metamodel';
mergedOpts.MetaType = 'PCE';
mergedOpts.Method = 'Quadrature';
mergedOpts.Display = 0; %turn off diplay

% create Input
mergedOpts.Input = childPCE.Internal.Input;

% assign model
mergedOpts.FullModel = parentPCE;

% get parent and child basis
parentBasis = parentPCE.PCE.Basis.Indices;
childBasis = childPCE.PCE.Basis.Indices;

% create union of child and parent basis
basisUnion = parentBasis;
% add only childBasis multi-indices that are not contained in
% parentBasis
basisUnion = [basisUnion; childBasis(~ismember(childBasis,parentBasis,'rows'),:)];
mergedOpts.TruncOptions.Custom = basisUnion;
mergedOpts.Degree = max(max(basisUnion));

% create projection
mergedPCE = uq_createModel(mergedOpts,'-private');

% extract basis and match with child
mergedBasis = mergedPCE.PCE.Basis.Indices;
matchedIndices_child = ismember(childBasis,mergedBasis,'rows');
matchedIndices_merge = ismember(mergedBasis,childBasis,'rows');

% add child coefficients to complete merge
mergedPCE.PCE.Coefficients(matchedIndices_merge) = ...
    mergedPCE.PCE.Coefficients(matchedIndices_merge) + ....
childPCE.PCE.Coefficients(matchedIndices_child);
end