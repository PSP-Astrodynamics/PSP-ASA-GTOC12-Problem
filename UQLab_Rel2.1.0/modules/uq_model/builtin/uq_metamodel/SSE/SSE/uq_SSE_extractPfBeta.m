function evolution = uq_SSE_extractPfBeta(obj)
% UQ_SSE_EXTRACTPFBETA extracts the evolution of Pf and Beta from an SSER.
 
% init
PfContainer = zeros(obj.currRef,3);
CoVContainer = zeros(obj.currRef,1);

% extract betas
for rr = 0:obj.currRef-1
    % current terminal domains
    currDomsIdx = obj.Graph.Nodes.ref <= rr;
    % loop over terminal domains and remove those, whose successors
    % have an rr <= rr
    for kk = find(currDomsIdx)'
        currSuccessors = successors(obj.Graph,kk);
        successorRef = obj.Graph.Nodes.ref(currSuccessors);
        % assign true to invalid successors if condition is met
        if all(successorRef <= rr) && ~isempty(currSuccessors)
            currDomsIdx(kk) = false;
        end
    end

    % compute Pf
    currPf = obj.Graph.Nodes.Pf(currDomsIdx,:);
    currPfRepl = obj.Graph.Nodes.PfRepl(currDomsIdx,:);
    currInputMass = obj.Graph.Nodes.inputMass(currDomsIdx);

    PfRepl = currInputMass'*currPfRepl;
    PfCI = quantile(PfRepl,[0.025,0.975]);
    PfMed = currInputMass'*currPf(:,1);
    % store
    PfContainer(rr+1,:) = [PfMed, PfCI];
    
    % Coefficient of variation
    CoVContainer(rr+1) = std(PfRepl)/PfMed;
end

% compute Beta
BetaContainer = -norminv(PfContainer);
% Switch columns of upper and lower bounds
BetaCI = BetaContainer(:,2:3);
BetaContainer(:,[3,2]) = BetaCI;

% return
evolution.Pf = PfContainer;
evolution.Beta = BetaContainer;
evolution.CoV = CoVContainer;
end