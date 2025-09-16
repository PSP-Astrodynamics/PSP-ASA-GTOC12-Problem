function Xnew = uq_enrich_lhs(X, N)
% Xnew = UQ_ENRICH_LHS(X,N) enriches a set of samples stored in X that form
% a Latin Hypercube design with N additional samples so that Xnew with X
% resemble as close as possible a latin hypercube design
% 
% References:
%
% Wang, G. (2003), Adaptive response surface method using inherited Latin 
% Hypercube design points. J Mech Design 125:210-220.

% Get the number of marginals (M) and the initial number of points (N0)
[N0, M] = size(X) ;

% Calculate total number of points
Ntot = N + N0 ;

% Find the indices of the already occupied cells
idx_remove = floor(X*Ntot) + 1 ;

% if point is at boundary (1), shift index to last cell
outOfBounds = idx_remove(:) == Ntot + 1;
idx_remove(outOfBounds) = Ntot;

% Build the full indices matrix
idx = repmat((1:Ntot).',1,M) ;

% 'Remove' indices of already occupied cells by setting their value to 0
idxr = sub2ind(size(idx), idx_remove, repmat( 1:M, size(idx_remove,1), 1 ));
idx(unique(idxr)) = 0;

% Randomly permute the non-zero indices of each column and select N
% M-tuples from them 
idx_final = zeros(N,M) ;
for ii = 1 : M
   nzidx = find(idx(:,ii)>0) ; % the non-zero indices
   idx_final(:,ii) = idx(nzidx(randperm(length(nzidx),N)),ii);
end
idx = idx_final ; 

% Sort the indices in ascending order (per column) 
idx = sort(idx,1);

% get LHS samples
lhsSamples = uq_lhs(N,M);

% Find the cell indices of the LHS samples
lhs_idx = floor(lhsSamples*N) + 1 ;

% Map these indices to the indices of the full Latin Hypercube
lhs_idx_conv = idx(lhs_idx + repmat(0:M-1,N,1)*N) ;

% Map the lhs samples to the corresponding unoccupied cells of the full
% Latin Hypercube
Xnew = N/Ntot * lhsSamples + (lhs_idx_conv - lhs_idx)/ Ntot ;