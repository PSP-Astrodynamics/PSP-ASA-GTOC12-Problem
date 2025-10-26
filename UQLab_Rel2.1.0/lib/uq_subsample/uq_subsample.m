function [Xnew, idx] = uq_subsample(X,NK, method, varargin)
% UQ_SUBSAMPLE Reduces the size of the experimental design X from N to NK
% samples picked from X based on various methods described below.  
%
% UQ_SUBSAMPLE(X, NK, 'random') returns a subset Xnew (NKxM) of X (NxM),
% based on random selection
%
% UQ_SUBSAMPLE(X, N, 'kmeans') returns a subset Xnew (NKxM) of X
% (NxM). A set of NK clusters is computed by performing k-means clustering 
% on X. Then the NK samples closest to each cluster centroid are selected
%
% UQ_SUBSAMPLE(X, N, 'kmeans','Distance_kmeans','type') allows to specify the 
% distance metric used in k-means clustering. See the documention 
% of the MATLAB builtin kmeans algorithm (option 'Distance') for possible 
% values of 'type'
% 
% UQ_SUBSAMPLE(X, N, 'kmeans','Distance_nn','type') allows to specify the 
% distance metric used in the nearest neighbour search. See the documention 
% of the MATLAB builtin knnsearch algorithm (option 'Distance') for possible 
% values of 'type'. Additional parameters can be supplied, if required,
% such as the 'P' exponent in case of Minkowski distance
%
% Xnew = UQ_SUBSAMPLE(X, NK, method, ...) returns an NKxM matrix (where M is the number 
% of columns in X) that corresponds to reduced samples (that already belong to X)
%
% [Xnew, idx] = UQ_SUBSAMPLE(...) additionally returns the indices of 
% the selected samples

if nargin < 3 
   error('Not enough input arguments!') 
end  

switch lower(method)
    case {'random','rand'}
        [Xnew, idx] = uq_subsample_random(X, NK);
    case {'k-means','kmeans'}
        [Xnew, idx] = uq_subsample_kmeans(X, NK, varargin{:});
    otherwise
        error('Unknown method!')
end
    
    
