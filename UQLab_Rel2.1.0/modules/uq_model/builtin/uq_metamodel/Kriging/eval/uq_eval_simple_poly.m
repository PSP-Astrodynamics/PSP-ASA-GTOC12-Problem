function simplePoly = uq_eval_simple_poly(degree,X)
%UQ_EVAL_SIMPLE_POLY constructs a univariate polynomials on vector X.
%
%   Univariate polynomials of X is N-by-(degree+1) and of the form:
%   1 + X + X^2 + ... + X^(degree). Note that order = degree+1.
    
% Make sure X is a column vector
if size(X,2) ~= 1
    errMsg = ['uq_eval_simple_poly is designed to work with X',...
        'in column vector format'];
    error(errMsg);
end

% Recursively calculates the polynomial value up to the requested degree
simplePoly = ones(numel(X), degree+1);
for ii = 1:degree
    simplePoly(:,ii+1) = simplePoly(:,ii).*X;
end
