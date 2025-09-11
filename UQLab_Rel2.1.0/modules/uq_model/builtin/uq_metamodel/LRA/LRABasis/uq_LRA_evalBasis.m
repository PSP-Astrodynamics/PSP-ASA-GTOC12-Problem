function P = uq_LRA_evalBasis(U, BasisParameters, p)
% This function evaluates the univariate polynomials of degree up to p at
% the set U; it returns a cell array with each cell corresponding to one
% input variable
%
% It is implemented as a wrapper to uq_eval_univ_basis.

BasisParameters.MaxDegrees = p;
P_mat = uq_eval_univ_basis(U, BasisParameters);

% The following post processing is needed for consistency with the LRA module. The LRA
% module expects P to be a cell-array of polynomial evaluations.

M = size(P_mat,2);
P = cell(1,M);

for i=1:M
    P{i} = squeeze(P_mat(:,i,:));
end
