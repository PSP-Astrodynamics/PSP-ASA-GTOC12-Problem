function [hypercubeX, hypercubeY, binIdx] = uq_getHypercubeBins(X,Y,variables,binEdges)
%UQ_GETHYPERCUBEBINS some bla
%   detailed bla

%% Initialization
% get indices of points that lie inside the supplied edges
NDims = length(variables);
NPoints = size(X,1);
M = size(X,2);
MOut = size(Y,2);

% alternatives: 1=no preallocation, copying, 2=preallocation
alternative = 1;

% count the bins in each dimension
bins = cellfun(@(x) length(x)-1, binEdges);
% make sure the bins array is a row
if size(bins,1) > 1 && size(bins,2) == 1
    bins = bins';
elseif size(bins,1) ~= 1 && size(bins,2) ~= 1
    error('While preparing the hypercube for the conditional moments!')
end

% preallocate
if numel(bins) == 1
    hypercubeX = cell(bins,1);
else
    hypercubeX = cell(bins);
end
binIdx = zeros(NPoints,NDims);

%% Find what bins the sample points belong to
% go through all constaining dimensions
for dd = 1:NDims
    % get the current dimensions bin edges and compare them with the
    % current point to find in which bin the point lies
    currEdges = binEdges{dd};
    larger = X(:,variables(dd)) >= currEdges(1:end-1);
    smaller = X(:,variables(dd)) < currEdges(2:end);
    % we want to apply the FIND function to each row. We use a trick
    binIdx(:,dd) = sum( cumprod(and(larger,smaller) == 0, 2), 2) + 1;
end

%% Move the sample points to their bins

% alternative 2:
% if we extend the hypercube bins with each sample that belongs there, all
% the ones that are already there are copied. To accelerate this process,
% we can preallocate too much space and remove unused space afterwards.
% a cleverer preallocation with less points could be done, when we know
% we're using quantile bins: per bin ~NPoints/sum(bins) points
if alternative == 1
    hypercubeY = hypercubeX;
elseif alternative == 2
    hypercubeX = cellfun(@(x) zeros(NPoints, M), hypercubeX, 'UniformOutput', false);
    hypercubeY = cellfun(@(x) zeros(NPoints, MOut), hypercubeX, 'UniformOutput', false);
end

for ii = 1:NPoints
    % first we convert the index (in array form) to a cell
    currentidx = num2cell(binIdx(ii,:));
    % now we can use it as an index
    
    if alternative == 1
    % alternative 1: copy and attach: takes a long time for large bins
    hypercubeX{currentidx{:}} = [hypercubeX{currentidx{:}}; X(ii,:)];
    hypercubeY{currentidx{:}} = [hypercubeY{currentidx{:}}; Y(ii,:)];
    
    elseif alternative == 2
    % alternative 2: move sample to its bin
    hypercubeX{currentidx{:}}(ii,:) = X(ii,:);
    hypercubeY{currentidx{:}}(ii,:) = Y(ii,:);
    end
end

if alternative == 2
    % remove empt rows from bins
    for ii = 1:NDims
        % set the index
        runidx = repmat({':'}, NDims,1);
        
        for jj = 1:bins(ii)
            runidx{ii} = jj;
            
            % find and delete empty rows in hypercubeX cells
            currentbinX = hypercubeX{runidx{:}};
            emptyrows = sum(~currentbinX,2)==M;
            currentbinX(emptyrows,:)=[];
            hypercubeX{runidx{:}} = currentbinX;
            
            % find and delete empty rows in hypercubeY cells
            currentbinY = hypercubeY{runidx{:}};
            emptyrows = sum(~currentbinY,2)==MOut;
            currentbinY(emptyrows,:)=[];
            hypercubeY{runidx{:}} = currentbinY;
        end
        
    end
end