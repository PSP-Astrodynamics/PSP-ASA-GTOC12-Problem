function varargout = uq_kmeans(X,NK,varargin)
% UQ_KMEANS K-means clustering library

NITER = 1000;
if ~exist('NK', 'var')
    NK = 3;
end

% Parse the input options
if ~isempty(varargin) 
    idx = find(strcmpi('weights', varargin),1);
    if ~isempty(idx)
        W = varargin{idx+1};
    end
    varargin(idx:idx+1)=[];
end

[N, M] = size(X);

if ~exist('W', 'var')
   W = ones(N,1); 
end

% Size matching for backward compatibility with Matlab R2014a
if size(W,2) == 1 && size(W,2) < size(X,2)
    W = repmat(W,1,size(X,2));
end
WX = W.*X;


%% INITIALIZATION
% create a random set of initial mean estimates
P = randperm(N,NK);
CC = X(P,:);
% standard clustering: iteratively refine clustering of points
for ii = 1:NITER
    % Get the distances to the current means
    % First try with distancemeasure squaredeuclidean which is more
    % efficient but not available in earlier versions of matlab (e.g.
    % Matlab R2014a, if not found go with stnaderd Euclidean distance)
    try
        dd = pdist2(X,CC,'squaredeuclidean');
    catch
        dd = pdist2(X,CC,'euclidean');
    end
    
    % Now get the indices
    [~, cidx] = min(dd,[],2);
    % And update the corresponding centroids
    for kk = 1:NK
        idx = cidx==kk;
        CC(kk,:) = sum(WX(idx,:),1)/sum(W(idx));
    end
end

varargout{1} = cidx;
varargout{2} = CC;