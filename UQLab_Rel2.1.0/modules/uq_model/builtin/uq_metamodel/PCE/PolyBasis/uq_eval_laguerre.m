function VALUE = uq_eval_laguerre(ORDER, X, params, nonrecursive)
% VALUE = UQ_EVAL_LAGUERRE(ORDER, X, PARAMS, NONRECURSIVE): evaluate
%     univariate orthonormal Laguerre polynomials up to order ORDER at the point
%     X and return the in Nx(ORDER+1) the array VALUE. X must be a column vector. 
%     The j-th column of VALUE corresponds to the Laguerre polynomial of degree
%     (j-1) evaluated on X. The parameters of the underlying Gamma dare
%     specified in the PARAMS array. If NONRECURSIVE is set to true, only
%     return the last ORDER.
%
% Input Parameters
%
% 'ORDER'          the maximum degree of the univariate polynomials
%                  to be computed (integer)
%
% 'X'              A column vector containing the points where the 
%                  polynomials are evaluated.
%
% 'params'         a 1x2 or 2x1 vector containing the parameters of the
%                  corresponding gamma pdf.
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
% See also: UQ_GAMMA_PDF, UQ_EVAL_HERMITE,UQ_EVAL_LEGENDRE,UQ_EVAL_REC_RULE,
% UQ_POLY_REC_COEFFS 

%% argument checking
% make sure the order is a non-negative scalar
if ~isnumeric(ORDER) || ~isscalar(ORDER) || ORDER < 0
    error('uq_eval_laguerre only operates on positive order polynomials');
end
    
% make sure X is a column vector, and not a row vector
if size(X,2) ~= 1
   error('uq_eval_laguerre is designed to work with X in column vector format');
end

% if "nonrecursive" is defined and positive, only use the current value
if ~exist('nonrecursive', 'var')
    nonrecursive = 0;
end

if length(params) < 2
	error('uq_eval_laguerre needs as input the parameters as given to the uq_gamma_pdf');
end

% Use the appropriate three-terms recursion rule to calculate the values of 
% the polynomials. An Gamma distribution with scaling parameter 1 is used.
AB = uq_poly_rec_coeffs(ORDER,'laguerre',[1 params(2)]);
VALUE = uq_eval_rec_rule(X,AB{1},nonrecursive);
