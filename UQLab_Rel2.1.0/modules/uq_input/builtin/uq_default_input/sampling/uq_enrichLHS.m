function [Xnew, uNew] = uq_enrichLHS(X, N, inpt)
% UQ_ENRICHLHS enriches an Latin Hypercube Design (LHD) with new points so that 
% the new set also forms a latin hypercube
%
% NOTE: UQ_ENRICHLHS requires that the initial set of samples indeed form a
% Latin Hypercube Design. If this requirement is not fulfilled please use
% uq_LHSify instead
%
% UQ_ENRICHLHS(X, N) enriches the current Latin Hypercube Design X, defined 
% by the currently selected input object by introducing N additional points
%
% UQ_ENRICHLHS(X, N, INPUT) allows to specify the the INPUT object that
% corresponds to X
%
% Xnew = UQ_ENRICHLHS(X, N, ...) returns an NxM matrix (where M is the number 
% of columns in X) that corresponds to the *new* samples (the already existing ones 
% in X are not included)
%
% [Xnew, uNew] = UQ_ENRICHLHS(...) additionally returns the *new*
% samples in the uniform space
%
% See also UQ_ENRICHSOBOL,UQ_LHSIFY

%% retrieve the input object
if exist('inpt', 'var')
    current_input = uq_getInput(inpt);
else
    current_input = uq_getInput;
end


%% Check whether the existing X is indeed a latin hypercube
[N0, M] = size(X);
u0 = zeros(size(X));
% get the indices of the marginals of type constant (if any)
Types = {current_input.Marginals(:).Type};
% get the indices of non-constant marginals
indConst = find(strcmpi(Types, 'constant'));
indNonConst = 1:length(Types);
indNonConst(indConst) = [];

% get the mapping of non-constant X to uniform space
% Assign marginals Types of  u marginals(uniform hypercube) that
% correspond to non-constant marginals
[uMarginals(indNonConst).Type] = deal('uniform') ;
% Assign marginals Parameters of  u marginals(uniform hypercube) that
% correspond to non-constant marginals
[uMarginals(indNonConst).Parameters] = deal([0 1]) ;
% Assign marginals Types of  u marginals(uniform hypercube) that
% correspond to constant marginals
[uMarginals(indConst).Type] = deal('constant') ;
% Assign marginals Parameters of  u marginals(uniform hypercube) that
% correspond to constant marginals
[uMarginals(indConst).Parameters] = deal(0.5) ;
% Fix the values of all u samples that correspond to constant
% marginal to 0.5 (mean of uniform distribution in [0,1])
u0 = zeros(size(X));
u0(:,indConst) = 0.5 * ones(N,length(indConst)) ;
% Build the copula submatrix that corresponds to non-constant marginals
% (Physical space)
copulaNonConst.Type = current_input.Copula.Type ;
copulaNonConst.Parameters = current_input.Copula.Parameters(indNonConst,indNonConst);
copulaNonConst.Parameters = current_input.Copula.Parameters(indNonConst,indNonConst);
% Build the copula submatrix that corresponds to non-constant marginals
% (uniform space) : Its independent so the Type would suffice
uCopulaNonConst.Type = 'Independent';

% Now we can get the mapping from X to u (non-constants)
u0(:,indNonConst) = uq_GeneralIsopTransform(...
    X(:,indNonConst),...
    current_input.Marginals(indNonConst), ...
    copulaNonConst, ...
    uMarginals(indNonConst),...
    uCopulaNonConst);
% find the indices of the occupied cells in the initial design
idx_init = floor(u0*N0) + 1 ;
% check whether all of them are unique
isLHS = 1;
for ii = 1 : M
    isLHS = isLHS & (length(unique(idx_init(:,ii))) == N0);
end

if isLHS
    [Xnew, uNew] = uq_enrichSample(X, N, 'LHS', current_input);
else
    msg = ['The initial sample set does not form a Latin Hypercube!',...
        ' For eniriching such set in a pseudo-LHS fashion use uq_LHSify function instead.']; 
   error(msg) 
end





