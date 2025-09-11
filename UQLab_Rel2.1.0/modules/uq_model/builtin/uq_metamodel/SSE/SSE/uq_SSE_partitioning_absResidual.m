function newDomains = uq_SSE_partitioning_absResidual(obj, subIdx)
% UQ_SSE_PARTITIONING_ABSRESIDUAL returns the partitioned domains based on 
%    a strategy that attempts to isolate regions with large from regions 
%    with small absolute residuals.
%
%    NEWDOMAINS = UQ_SSE_PARTITIONING_ABSRESIDUAL(OBJ, SUBIDX) returns the
%    partitioned domain bounds NEWDOMAINS

% get current bounds and currPCE
currBounds = obj.Graph.Nodes.bounds{subIdx};

% spliting coordinates
currIdx = uq_SSE_inBound(obj.ExpDesign.U, currBounds);
Ucurr = obj.ExpDesign.U(currIdx,:);
ResCurr = obj.ExpDesign.Res(currIdx);
YCurr = obj.ExpDesign.Y(currIdx);
for ii = 1:obj.Input.Dim
    % get candidate partitions in-between sequence of points
    ucurr = Ucurr(:,ii);
    u = sort(ucurr);
    uCand = u(1:end-1) + diff(u)/2;
    
    % compute learning function for each partition
    for jj = 1:length(uCand)
        isBelowCand = ucurr < uCand(jj);
        mean1 = mean(YCurr(isBelowCand));
        mean2 = mean(YCurr(~isBelowCand));
        % fill error container
        errorContainer(ii,jj) = sum((YCurr(isBelowCand)-mean1).^2) + sum((YCurr(~isBelowCand)-mean2).^2);
    end
end

% find extreme error
sortedIdx = uq_SSE_sortValues(errorContainer(:),'ascend');
[splitDim, splitIdx] = ind2sub(size(errorContainer),sortedIdx(1));

% compute bounds split
boundsSplit = Ucurr(splitIdx,splitDim)+diff(Ucurr(splitIdx:splitIdx+1,splitDim))/2;

% create low and up bounds
boundsLow = currBounds(1,:);
boundsUp = currBounds(2,:);
    
% create split bounds
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