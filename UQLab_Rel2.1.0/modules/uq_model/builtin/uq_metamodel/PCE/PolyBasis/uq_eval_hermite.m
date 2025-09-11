function VALUE = uq_eval_hermite(ORDER, X, nonrecursive)
% VALUE = UQ_EVAL_HERMITE(ORDER, X, NONRECURSIVE): evaluate
%     univariate orthonormal Hermite polynomials up to order ORDER at the point
%     X and return the in Nx(ORDER+1) the array VALUE. X must be a column vector. 
%     The j-th column of VALUE corresponds to the hermite polynomial of degree
%     (j-1) evaluated on X. If NONRECURSIVE is set to true, only return the
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
% Optional Input Parameters:
%
%  'nonrecursive'  If it exists and evaluates to 'true' then only the
%                  values for polynomial of order ORDER are returned.
%
% Return values:
%
%  'VALUE'         The values of the polynomials up to degree defined by ORDER
%
% See also: UQ_GAUSSIAN_PDF,UQ_EVAL_LAGUERRE,UQ_EVAL_LEGENDRE,
% UQ_EVAL_REC_RULE,UQ_POLY_REC_COEFFS 


%% arguments checking
% make sure the order is a non-negative scalar
if ~isnumeric(ORDER) || ~isscalar(ORDER) || ORDER < 0
    error('uq_eval_hermite only operates on positive order polynomials');
end
    
% make sure X is a column vector, and not a row vector
if size(X,2) ~= 1
   error('uq_eval_hermite is designed to work with X in column vector format');
end

% if "nonrecursive" is defined and positive, only use the current value
if ~exist('nonrecursive', 'var')
    nonrecursive = 0;
end

AB = uq_poly_rec_coeffs(ORDER,'hermite');
VALUE = uq_eval_rec_rule(X,AB{1},nonrecursive);
