function K = uq_eval_PosteriorCorrelationMatrix(X1,X2,X,theta,options,Rinv)
% UQ_POSTERIORCORRELATIONMATRIX computes the posterior (cross-)correlation
% matrix of two Gaussian random vectors X1 and X2, conditioned ot X.
% 
% K = UQ_POSTERIORCORRELATIONMATRIX(X1, X2, X, THETA, OPTIONS, RINV)
% computes the N1-by-N2 correlation matrx matrix K for two inputs (N1-by-M)
% X1 and (N2-by-M) X2 given the kernel parameters THETA and additional 
% options specified in the structure and inverse of the correlation matrix
% Rinv = R^-1(X,X). 
% 
% See uq_eval_kernel.m for more details on the options structure.
% Rinv is optional, if not provided it is calculated using the given
% correlation options.

% Calculate the correlation matrix
K = uq_eval_Kernel(X1, X2, theta, options) ;

% Calculate the cross-correlation matrix ebtween X1 and dataset X ;
k_X1 = uq_eval_Kernel(X1, X, theta, options) ;

% Calculate the cross-correlation matrix between X2 and dataset X ;
if  (size(X1,1) == size(X2,1)) && isequal(X1,X2)
k_X2 = k_X1 ;
else
    k_X2 = uq_eval_Kernel(X2, X, theta, options) ;
end

% Calculate the inverse of the Gram matrix on the conditionning data, if
% not available already
if nargin < 6
    R = uq_eval_Kernel(X, X, theta, options) ;
    Rinv = inv(R) ;
end

% Calculate the posterior correlation matrix
K = K - k_X1 * Rinv * transpose(k_X2) ;

end



