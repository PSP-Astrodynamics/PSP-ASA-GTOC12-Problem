function obj = uq_SSE_flatten(obj, maxRefine)
% OBJ = UQ_SSE_FLATTEN(OBJ): flattens and SSE OBJ, i.e. reduces the number
%     of levels to 1 by recomputing the expansions in the terminal domains
%
%     UQ_SSE_FLATTEN(OBJ, MAXREFINE) Considers only the expansions up until
%       the prescribed level

if nargin < 2
    % take the maximum available refinement level
    maxRefine = inf;
else
    if ~(length(maxRefine) == 1) || floor(maxRefine) ~= maxRefine
        error('maxRef has to be a scalar integer')
    end
end

% output
fprintf('\nStarting flattening...\n')

% get current ref
DeepGraph = obj.Graph;

% remove nodes above currRef
if ~isinf(maxRefine)
    removeNodes = find(DeepGraph.Nodes.ref>maxRefine);
    DeepGraph = rmnode(DeepGraph,removeNodes);
end

% take last nodes
outGoing = outdegree(DeepGraph);
terminalIndices = find(outGoing==0);

% copy terminal nodes and PCEs from graph
FlatGraph = subgraph(DeepGraph,terminalIndices);
DeepGraphExpansions = FlatGraph.Nodes.expansions;
for tt = 1:numnodes(FlatGraph)
    % determine list of predecessors by computing shortest path
    % between tt and 1 (first node)
    termIdFull = terminalIndices(tt);
    predList = shortestpath(DeepGraph,1,termIdFull);
    predList = predList(1:end-1); % remove tt
    % loop over pred list and flatten
    for kk = predList
        % create flattened Expansion
        currExpansion = DeepGraph.Nodes.expansions{kk};
        if kk == predList(1)
            % first pred list entry
            if ~isempty(DeepGraphExpansions{tt})
                % node has Expansion
                terminalExpansion = DeepGraphExpansions{tt};
                mergedExpansion = uq_SSE_mergePCEToChild(currExpansion,terminalExpansion);
            else
                % node does not have an Expansion, project onto current subdomain
                terminalBounds = FlatGraph.Nodes.bounds{tt};
                mergedExpansion = uq_SSE_mergePCEToChild(currExpansion,terminalBounds);
            end
        else
            % later entries, use already flattened Expansions
            terminalExpansion = FlatGraph.Nodes.expansions{tt};
            mergedExpansion = uq_SSE_mergePCEToChild(currExpansion,terminalExpansion);
        end

        % assign to structure
        FlatGraph.Nodes.expansions(tt) = {mergedExpansion};
    end
end

% assign to obj
obj.FlatGraph = FlatGraph;

% output
fprintf('...finished flattening!\n')
end