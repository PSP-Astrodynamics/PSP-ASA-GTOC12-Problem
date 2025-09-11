function moments = uq_SSE_outputMoments(SSE)
% UQ_SSE_OUTPUTMOMENTS(MODEL) uses a calculated SSE metamodel to compute the
%     output mean and variance. Only works with flattened SSE
%     representation
%     single output as specified in CURRENT_MODEL
%
% See also: UQ_SSE_FLATTEN

% check if flattened
if isempty(SSE.FlatGraph)
    error('Only works with flattened representation!')
end

%% Prepare
% get terminal domain ids
FlatGraph = SSE.FlatGraph;

%% Compute expectation
meanVal = 0;
% loop over terminal domains
for ii = 1:numnodes(FlatGraph)
    currInputMass = FlatGraph.Nodes.inputMass(ii);
    currExpansion = FlatGraph.Nodes.expansions{ii};
    
    % get constant polys coefficient
    a0 = currExpansion.PCE.Coefficients(1);
    
    % add to mean
    meanVal = meanVal + a0*currInputMass;
end
% return
moments.Mean = meanVal;

%% Compute Variance
varVal = 0;
% loop over terminal domains
for ii = 1:numnodes(FlatGraph)
    currInputMass = FlatGraph.Nodes.inputMass(ii);
    currExpansion = FlatGraph.Nodes.expansions{ii};
    
    % get constant polys coefficient
    a = sum(currExpansion.PCE.Coefficients(1:end).^2);
    
    % add to mean
    varVal = varVal + a*currInputMass;
end
% return
moments.Var = varVal - moments.Mean^2;

end