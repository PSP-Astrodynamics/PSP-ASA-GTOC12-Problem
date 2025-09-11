function idx = uq_SSE_sortValues(values, sortType, randomize)
% UQ_SSE_SORTVALUES sorts a vector
%
%    IDX = UQ_SSE_SORTVALUES(VALUES, SORTTYPE, RANDOMIZE) sorts the VALUES
%    in SORTTYPE, i.e. 'ascend' or 'descend' order and randomizes if equal
%    values are passed in VALUES

% determine if randomized or not
if nargin > 2 && randomize
    % sample randomly from multinomial distribution
    dummyVals = zeros(size(values));
    for ii = 1:length(values)
        currID = find(mnrnd(1,values./sum(values)));
        dummyVals(currID) = length(values) - ii;
        values(currID) = 0;
    end
    values = dummyVals;
end
% sort total errors and return index
[values, idx] = sort(values, sortType);

% if identical errors, sort randomly
[~,~,uniqueID] = unique(values);
for ii = 1:max(uniqueID)
    nOccurences = sum(uniqueID == ii);
    if nOccurences > 1
        currIDs = idx(uniqueID == ii);
        % sort randomly
        currIDs = currIDs(randperm(nOccurences));
        % return
        idx(uniqueID == ii) = currIDs;
    end
end
end