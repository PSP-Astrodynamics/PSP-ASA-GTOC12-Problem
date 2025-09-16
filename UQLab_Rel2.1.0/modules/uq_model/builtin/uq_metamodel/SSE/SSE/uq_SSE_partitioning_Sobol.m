function newDomains = uq_SSE_partitioning_Sobol(obj, subIdx)
% UQ_SSE_PARTITIONING_SOBOL returns the partitioned domains based on an
%    equal-mass partitioning strategy that splits in the direction of the
%    maximum first-order Sobol' index.
%
%    NEWDOMAINS = UQ_SSE_PARTITIONING_SOBOL(OBJ, SUBIDX) returns the
%    partitioned domain NEWDOMAINS

% get current bounds and currPCE
currBounds = obj.Graph.Nodes.bounds{subIdx};

% spliting coordinates
boundsSplit = mean(currBounds);

% create low and up bounds
boundsLow = currBounds(1,:);
boundsUp = currBounds(2,:);

% compute sobol index and take maximum sobol index as split dimension
currExpansion = obj.Graph.Nodes.expansions{subIdx};
% compute Sobol' indices
SobolAnalysis.Type = 'Sensitivity';
SobolAnalysis.Method = 'Sobol';
SobolAnalysis.Model = currExpansion;
SobolAnalysis.Input = obj.Input.Independent;
SobolAnalysis.Display = 'quiet';
mySobolAnalysis = uq_createAnalysis(SobolAnalysis, '-private');
% replace NaN by 0
SortErrors = mySobolAnalysis.Results.FirstOrder;
SortErrors(isnan(SortErrors)) = 0;
sortedIds = uq_SSE_sortValues(SortErrors,'descend');
splitDim = sortedIds(1);
    
% create split bounds
boundsSplit = boundsSplit(:,splitDim);
boundsSplit = boundsSplit(~isnan(boundsSplit)); % remove nans
if ~isempty(boundsSplit)
    % create new domains
    nSplitDoms = length(boundsSplit)+1;
    for ii = 1:nSplitDoms
        % init with full current domain bounds
        boundsLow_curr = boundsLow;
        boundsUp_curr = boundsUp;
        % overwrite split direction
        if ii == 1
            % just update upper bound
            boundsUp_curr(splitDim) = boundsSplit(ii);
        elseif ii == nSplitDoms
            % just update lower bound
            boundsLow_curr(splitDim) = boundsSplit(ii-1);
        else
            % update bounds bounds
            boundsLow_curr(splitDim) = boundsSplit(ii-1);
            boundsUp_curr(splitDim) = boundsSplit(ii);
        end
        % assign to new domain
        newBounds = [boundsLow_curr; boundsUp_curr];
        newDomains(ii).bounds = newBounds;
        newDomains(ii).inputMass = uq_SSE_volume(newBounds);
    end
else
    % return empty
    newDomains = [];
end
end