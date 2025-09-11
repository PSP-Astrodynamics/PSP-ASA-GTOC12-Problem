function [momentsY,probInBin] = uq_condMoments(xx, yy, condVars, options)
%UQ_CONDMOMENTS computes the conditional mean and variance of Y|X_condVars.
%
%   MOMENTSY = UQ_CONDMOMENTS(XX, YY, CONDVARS, OPTIONS) estimates the
%   first two conditional moments (mean and variance) of Y|X_condVars based
%   on given samples of XX and YY. The function returns a structure that
%   provides two LENGTH(CONDVARS)-dimensional hypercubes. One hypercube
%   contains the bin-wise conditional mean, and another contains the
%   variance. If YY is a N-by-N2 matrix then each bin with conditional
%   moments contains 1-by-N2 conditional moments.
%
%   [MOMENTSY,PROBINBIN] = UQ_CONDMOMENTS(...) additionally returns the
%   probability for a point to lie in each bin.
%
%   Note:
%
%   - (Hyper)bins with less than three points are not taken into account
%     in the computation of the moments.
%
%   See also UQ_BINSAMPLES.

%% Initialization
N = size(xx,1);  % Number of sample points
nDim = length(condVars);  % Number of conditioned variables
binEdges = cell(1,nDim);

% Check the options for binning options
nBins = options.nBins;
strategy = options.binStrat;

%% Binning

% Start with 1-dimensional binning along each conditioning variable
hOverlap = 0.0;  % No overlap in the binning
for ii = 1:length(condVars)
    binEdges{ii} = uq_binSamples(...
        xx(:,condVars(ii)), nBins, strategy, hOverlap);
end

% Count the number bins in each dimension
bins = cellfun(@(x) length(x)-1, binEdges);
% Make sure the bins array is a (1-by-nDim) cell array
if size(bins,1) > 1 && size(bins,2) == 1
    bins = transpose(bins);
elseif size(bins,1) ~= 1 && size(bins,2) ~= 1
    error('While preparing the hypercube for the conditional moments!')
end



% Find out which bins the sample points belong to
% by going through all constraining dimensions
binIdx = zeros(N,nDim);  % The hyberbin index for each sample point
nElementsMax = 1e8;  % Maximum number of elements in an array
for dd = 1:nDim
    % Compute chunks
    currEdges = binEdges{dd};
    chunkSize = floor(nElementsMax/numel(currEdges));
    nChunks = floor(size(xx,1)/chunkSize);
    nChunksRemainder = mod(size(xx,1),chunkSize);
    % Do chunk-wise processing here
    for ii = 1:nChunks
        idx = ((ii-1)*chunkSize+1):(ii*chunkSize);
        isLarger = bsxfun(@ge, xx(idx,condVars(dd)), currEdges(1:end-1));
        isSmaller = bsxfun(@lt, xx(idx,condVars(dd)), currEdges(2:end));
        combBin = and(isLarger,isSmaller);
        binIdx(idx,dd) = sum(cumprod(combBin == 0, 2), 2) + 1;
    end
    % Process the remainder 
    if nChunksRemainder > 0
        idx = (nChunks*chunkSize)+1:size(xx,1);
    end
    isLarger = bsxfun(@ge, xx(idx,condVars(dd)), currEdges(1:end-1));
    isSmaller = bsxfun(@lt, xx(idx,condVars(dd)), currEdges(2:end));
    combBin = and(isLarger,isSmaller);
    binIdx(idx,dd) = sum(cumprod(combBin == 0, 2), 2) + 1;
end

%% Compute the conditional moments

% Get the indices of points that belong to the same bin
[~,~,sameIdx] = unique(binIdx,'rows');
momentsY.mean = zeros(numel(unique(sameIdx)),size(yy,2));
momentsY.variance = zeros(numel(unique(sameIdx)),size(yy,2));
for oo = 1:size(yy,2)
    % Compute mean for each bin
    momentsY.mean(:,oo) = accumarray(sameIdx, yy(:,oo), [], @mean);
    % Compute variance for each bin
    momentsY.variance(:,oo) = accumarray(sameIdx, yy(:,oo), [], @var);
end
% Compute the probability of a point to be in a bin
probInBin = accumarray(sameIdx, ones(numel(sameIdx),1), [], @sum)/N;

end
