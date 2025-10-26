function newDomains = uq_SSE_partitioning_misclass(obj, subIdx)
% UQ_SSE_PARTITIONING_MISCLASS returns the partitioned domains based on a
%    nonequal-mass partitioning strategy that splits at the location and 
%    direction so as to isolate regions with a high misclassification
%    probability from regions with a low misclassification probability.
%
%    NEWDOMAINS = UQ_SSE_PARTITIONING_MISCLASS(OBJ, SUBIDX) returns the
%    partitioned domain bounds NEWDOMAINS

% get current bounds and currPCE
currBounds = obj.Graph.Nodes.bounds{subIdx};

% spliting coordinates
History = obj.Graph.Nodes.History(subIdx);   
Y = History.Y;
F = History.U;
Yrepl = History.Yrepl;

% misclassification probability
p0 = 0.01;
misclassIdx = uq_SSE_misclassSample(Y,Yrepl,p0);

% split into relevant and irrelevant samples
Frelev = F(misclassIdx,:);
Firrelev = F(~misclassIdx,:);

% non constant
maxVal = nan(obj.Input.Dim,1); uSplit = nan(obj.Input.Dim,1);
for currSplitIdx = 1:obj.Input.Dim
    % compute
    relevSamples = Frelev(:,currSplitIdx);
    irrelevSample = Firrelev(:,currSplitIdx);

    % linear grid between domain bounds
    u = linspace(currBounds(1,currSplitIdx),currBounds(2,currSplitIdx),1e3);

    % compute probability that relevant and irrelevant samples lie
    % left and right of split
    relevLeft = mean(relevSamples < u,1); relevRight = 1 - relevLeft;
    irrelevLeft = mean(irrelevSample < u,1); irrelevRight = 1 - irrelevLeft;

    % learning function
    learnFun = max([relevLeft + irrelevRight;relevRight + irrelevLeft],[],1);

    % find split point according to learning function
    [maxVal(currSplitIdx),maxID] = max(learnFun);
    uSplit(currSplitIdx) = u(maxID);
    % find split point according to learning function
    % [maxVal(currSplitID),maxID] = max(max([(f(end)-f).*(u-u(1));f.*(u(end)-u)],[],1)); 
    % [maxVal(currSplitID),maxID] = max(max([(f(end)-f)+(u-u(1));f+(u(end)-u)],[],1));  
    % store maximum f content in both subdomains at split point
end
% compute sort errors
sortedIds = uq_SSE_sortValues(maxVal,'descend',false);
splitID = sortedIds(1);
% assign split bounds
boundsSplit(:,splitID) = uSplit(splitID);

% create low and up bounds
boundsLow = currBounds(1,:);
boundsUp = currBounds(2,:);

% based on largest continuous fail zone
splitDim = splitID;
    
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