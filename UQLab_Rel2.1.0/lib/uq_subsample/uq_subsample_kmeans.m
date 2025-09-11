function [Xs,idx] = uq_subsample_kmeans(X, Ns, varargin)
% UQ_SUBSAMPLE_KMEANS creates a subset XS (NS-by-M) of X (N-by-M) by k-means clustering.
%
%   A set of NS clusters is computed by performing k-means clustering on X
%   and the NS sample points that are closest to each cluster centroid
%   are selected.
%
%   XS = UQ_SUBSAMPLE_KMEANS(X,NS) returns a subset Xs (NS-by-M)
%   of X (N-by-M).
%
%   XS = uq_subsample_kmeans(X, NS, NAME, VALUE) allows for fine-tuning 
%   various parameters of the subsampling algorithm by specifying 
%   Name/Value pairs:
%
%       NAME                VALUE
%       'Distance_kmeans'   Distance measure used in the k-means
%                           clustering - String,
%                           default : 'sqeuclidean'.
%                           See the documentation for the KMEANS function
%                           for details.
%       'Distance_nn'       Distance measure used in the nearest-neighbor
%                           search for determining the sample points
%                           closest to the k-means centroids - String,
%                           default : 'euclidean'.
%                           See the documentation for the KNNSEARCH
%                           function for detail.
%
%   [XS,IDX] = UQ_SUBSAMPLE_KMEANS(X,NS) additionally returns the indices
%   of the selected samples.
%
%   Additional notes:
%
%   - Strictly speaking, this method is more appropriately referred
%     to as the k-medoid sampling.
%
%   - This function utilizes MATLAB functions KMEANS and KNNSEARCH
%     for the k-means clustering and the nearest-neighbor search,
%     respectively. Both functions are part of the Statistics and Machine
%     Learning Toolbox.
%
%   See also: UQ_SUBSAMPLE_RANDOM, KMEANS, KNNSEARCH

%% Input processing
if nargin > 2
    parse_keys = {'Distance_kmeans', 'Distance_nn'};
    parse_types = {'p', 'p'};
    [uq_cline, varargin] = uq_simple_parser(varargin,...
        parse_keys, parse_types);
end

%% k-mean clustering subsampling
%
% Find the n cluster centroids
if nargin > 2 && ~strcmpi(uq_cline{1},'false')
    % use the specified distance metric
    kmeans_dist = uq_cline{1};
    [~,C] = kmeans(X, Ns, 'Distance', kmeans_dist);
else
    % use the default distance metric in knn-search
    [~,C] = kmeans(X,Ns);
end

% Find the nearest neighbor of each centroid in X
if nargin > 2 && ~strcmpi(uq_cline{2},'false')
    % use the specified distance metric
    % (with any additional options, if any)
    nn_dist = uq_cline{2};
    idx = knnsearch(X, C, 'Distance', nn_dist, varargin{:});
else
    % use the default distance metric in knn-search
    idx = knnsearch(X,C);
end

% Return the NK nearest neighbors
Xs = X(idx,:);

end