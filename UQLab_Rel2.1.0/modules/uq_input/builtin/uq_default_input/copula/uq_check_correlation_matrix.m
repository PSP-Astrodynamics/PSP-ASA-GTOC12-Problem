function success = uq_check_correlation_matrix(C)
% success = uq_check_correlation_matrix(C)
%     Checks if C is a well defined correlation matrix. Raises error
%     otherwise.

success = 0;

[d1, d2] = size(C);
if d1 ~= d2                             % error if C is not a square matrix
    error('Error: C must be a square matrix')
elseif ~(max(max(abs(C - C'))) <= eps)   % error if C is not symmetric
    error('Error: Matrix C must be symmetric')
elseif max(abs(C(:))) > 1+eps           % error if C values are not in [-1,1]
    error('Error: The elements of C must take values in [-1,1]')
elseif not(all(abs(diag(C)-1) <= eps ))  % error if diagonal elements are not 1
    error('Error: Some diagonal elements of C are not 1')
elseif nnz(eig(C) > 0 ) < d1            % error if C is not positive definite
    error('Error: The copula matrix is not positive definite')
end

success = 1;
