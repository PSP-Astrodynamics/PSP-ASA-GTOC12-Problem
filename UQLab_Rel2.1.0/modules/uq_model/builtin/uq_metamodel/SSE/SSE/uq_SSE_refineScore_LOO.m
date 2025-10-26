function refineScore = uq_SSE_refineScore_LOO(obj, subIdx)
% UQ_SSE_REFINESCORE_LOO returns a measure for selecting a refinement 
%    domain based on the leave-one-out error.
%
%    REFINESCORE = UQ_SSE_REFINESCORE_LOO(OBJ, SUBIDX) returns the 
%    REFINESCORE for subdomain SUBIDX 

% get volume
volume = obj.Graph.Nodes.inputMass(subIdx);

% check if PCE in domain
if ~isempty(obj.Graph.Nodes.expansions{subIdx})
    % take current PCE
    currExpansion = obj.Graph.Nodes.expansions{subIdx};
else
    % take parent PCE
    parentIdx = predecessors(obj.Graph,subIdx);
    currExpansion = obj.Graph.Nodes.expansions{parentIdx};
end

% test if curr expansion has a leave-one-out error measure
if ~isfield(currExpansion.Error,'ModifiedLOO')
    error('Selected refinement score requires the modified leave-one-out error in the residual expansion.')
end

% weight by volume
refineScore = currExpansion.Error.ModifiedLOO*var(currExpansion.ExpDesign.Y,1,1)*volume;
end