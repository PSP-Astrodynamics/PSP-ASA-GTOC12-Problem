function refineScore = uq_SSE_refineScore_Pf(obj, subIdx)
% UQ_SSE_REFINESCORE_FAILUREPROBABILITY returns a score for selecting
%    a refinement domain based on the failure probability variance.    
%
%    REFINESCORE = UQ_SSE_REFINESCORE_FAILUREPROBABILITY(OBJ, SUBIDX) 
%    returns the REFINESCORE for subdomain SUBIDX 

% check if Bootstrapping is available
if ~isfield(obj.ExpOptions,'Bootstrap') || obj.ExpOptions.Bootstrap.Replications < 1
    error('uq_SSE_refineScore_Pf requires bootstrap Expansions!')
end

% check intermediate re-prioritization criterion
NIterBack = 3;
reprioritize_flag = false;
if obj.currRef >= NIterBack
    % extract Pf evolution
    evolution = uq_SSE_extractPfBeta(obj);
    PfEvolution = evolution.Pf(end-NIterBack+1:end,1);

    % if total Pf hasn't changed within margin, refocus
    thresh = 1e-3;
    if var(PfEvolution)/PfEvolution(end)^2 < thresh || PfEvolution(end) == 0
        % output to console
        %fprintf('Intermediate re-prioritization criterion triggered...\n')
        % rank domains with zero Pf based on size
        reprioritize_flag = true;
    end
end

% get volume
volume = obj.Graph.Nodes.inputMass(subIdx);

% get failure probability replications
Pf_repl = obj.Graph.Nodes.PfRepl(subIdx,:);

if ~reprioritize_flag
    % weight by volume
    refineScore = var(Pf_repl)'*volume^2;
else
    % consider only volume
    refineScore = volume;
end
end