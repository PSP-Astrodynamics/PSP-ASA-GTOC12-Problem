function newDomains = uq_SSE_partitioning_varDiff(obj, subIdx)
% UQ_SSE_PARTITIONING_VARDIFF returns the partitioned domains based on an
%    equal-mass partitioning strategy that splits in the direction that 
%    maximizes the residual variance difference.
%
%    NEWDOMAINS = UQ_SSE_PARTITIONING_VARDIFF(OBJ, SUBIDX) returns the
%    partitioned domain bounds NEWDOMAINS

% get current bounds and currPCE
currBounds = obj.Graph.Nodes.bounds{subIdx};

% spliting coordinates
boundsSplit = mean(currBounds);

% create low and up bounds
boundsLow = currBounds(1,:);
boundsUp = currBounds(2,:);

% compute bounds of subset candidates and estimate errors
bounds = zeros(2,2,obj.Input.Dim);
for ii = 1:obj.Input.Dim
    % get bounds and assign split specific new coordinate
    boundsLow_curr = boundsLow; boundsLow_curr(ii) = boundsSplit(ii);
    boundsUp_curr = boundsUp; boundsUp_curr(ii) = boundsSplit(ii);
    % assign to candidate
    % (low/up,dim)
    bounds(1,1,:) = boundsLow;
    bounds(1,2,:) = boundsUp_curr;
    bounds(2,1,:) = boundsLow_curr;
    bounds(2,2,:) = boundsUp;

    % compute errors in each of the two subdomains
    for jj = 1:2
        % get bounds and indices
        candBounds = reshape(bounds(jj,:,:),2,[]);
        currIdx = uq_SSE_inBound(obj.ExpDesign.U,candBounds);

        % fill error container
        errorContainer(ii,jj) = var(obj.ExpDesign.Res(currIdx));
    end
end

% find extreme error
sortedIdx = uq_SSE_sortValues(abs(diff(errorContainer,1,2)),'descend');
splitDim = sortedIdx(1);
    
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