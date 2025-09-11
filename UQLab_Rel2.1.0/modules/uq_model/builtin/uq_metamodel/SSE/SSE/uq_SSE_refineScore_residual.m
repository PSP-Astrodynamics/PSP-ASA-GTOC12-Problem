function refineScore = uq_SSE_refineScore_residual(obj, subIdx)
% UQ_SSE_REFINESCORE_RESIDUAL returns a score for selecting a 
%    refinement domain based on the average residual size in the current 
%    subdomain
%
%    REFINESCORE = UQ_SSE_REFINESCORE_RESIDUAL(OBJ, SUBIDX) returns the 
%    REFINESCORE for subdomain SUBIDX

% curr bounds
currBounds = obj.Graph.Nodes.bounds{subIdx};

% get volume
volume = obj.Graph.Nodes.inputMass(subIdx);

% get points in current domain
currIdx = uq_SSE_inBound(obj.ExpDesign.U,currBounds);

if sum(currIdx) == 0
    % if no points are inside domain, set error to 0
    e_emp = 0;
else
    % L2 error
    e_emp = mean((obj.ExpDesign.Res(currIdx)).^2);
end

% weight by volume
refineScore = e_emp*volume;
end