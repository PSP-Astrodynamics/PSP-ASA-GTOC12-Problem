function VALUE = uq_eval_jacobi(ORDER, X, jac_params, nonrecursive)
% VALUE = UQ_EVAL_JACOBI(ORDER, X, PARAMS, NONRECURSIVE): evaluate
%     univariate orthonormal Jacobi polynomials up to order ORDER at the point
%     X and return the in Nx(ORDER+1) the array VALUE. X must be a column vector. 
%     The j-th column of VALUE corresponds to the Jacobi polynomial of degree
%     (j-1) evaluated on X. The parameters of the underlying Beta distribution
%     are specified in the PARAMS array. If NONRECURSIVE is set to true, only return the
%     last ORDER.
%
% Input Parameters
%
% 'ORDER'          the maximum degree of the univariate polynomials to be computed
%                  (integer)
%
% 'X'              A column vector containing the points where the 
%                  polynomials are evaluated.
%
% 'jac_params'     The parameters of the corresponding Beta distribution
%                  bounded at the [0 1] interval.
%
% Optional Input Parameters:
%
%  'nonrecursive'  If it exists and evaluates to 'true' then only the
%                  values for polynomial of order ORDER are returned.
%
% Return values:
%
%  'VALUE'         The values of the polynomials up to degree defined by ORDER
%
% See also UQ_BETA_PDF, UQ_EVAL_HERMITE, UQ_EVAL_LAGUERRE,
% UQ_EVAL_LEGENDRE, UQ_EVAL_REC_RULE.


%% arguments checking
% make sure the order is a non-negative scalar
if ~isnumeric(ORDER) || ~isscalar(ORDER) || ORDER < 0
    error('uq_eval_jacobi only operates on positive order polynomials');
end
    
% make sure X is a column vector, and not a row vector
if size(X,2) ~= 1
   error('uq_eval_jacobi is designed to work with X in column vector format');
end

% if "nonrecursive" is defined and positive, only use the current value
if ~exist('nonrecursive', 'var')
    nonrecursive = 0;
end

if ~exist('jac_params')
    error('You should specify the parameters of the corresponding beta distribution')
end

if (not( length(jac_params) == 2 )  & not(length(jac_params) == 4))
    error('jac_params should at contain two entries greater than 0 for the distribution parameters and optionally the lower and upper bounds of the distribution.')
end

% Use the appropriate three-terms recursion rule to calculate the values of the
% polynomials
AB = uq_poly_rec_coeffs(ORDER,'jacobi',jac_params);
VALUE = uq_eval_rec_rule(X,AB{1},nonrecursive);
