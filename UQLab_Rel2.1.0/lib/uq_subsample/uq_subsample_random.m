function [Xs,idx] = uq_subsample_random(X,Ns)
% UQ_SUBSAMPLE_RANDOM creates a subset XS (NS-by-M) of X (N-by-M) by random selection.
%
%   XS = UQ_SUBSAMPLE_RANDOM(X,NS) returns a subset XS (NS-by-M) 
%   of X (N-by-M), based on random selection. NS has to be less than
%   or equal to N.
%
%   [XS,IDX] = UQ_SUBSAMPLE_RANDOM(X,NS) additionally returns the indices
%   of the selected sample points, such that XS = X(IDX,:).
%
%   See also: UQ_SUBSAMPLE_KMEANS

% Pick sample indices at random
idx = randperm(size(X,1),Ns);

% Return the selected samples
Xs = X(idx,:);

end