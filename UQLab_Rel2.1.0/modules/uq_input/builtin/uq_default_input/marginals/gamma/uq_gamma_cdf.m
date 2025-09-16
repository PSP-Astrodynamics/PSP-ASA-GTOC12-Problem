function F = uq_gamma_cdf( X, parameters )
% UQ_GAMMA_CDF(X, parameters) calculates the Cumulative Density Function
% values of samples X  that follow a Gamma distribution with parameters specified in the vector
% 'parameters'
%
% Input parameters:
%
%     'X'             The samples
%
%     'parameters'    contains [lambda, k]
%
% NOTE: 
% Please keep in mind the differences in the notation of the parameters
% between MATLAB and UQLab
% MATLAB notation : cdf = F(x|a,b)
% UQLab notation  : cdf = F(x|lambda,k) , lambda = 1/b , k=a
%
% See also GAMCDF
%
lambda = parameters(1);
k = parameters(2);

F = gamcdf(X, k, 1/lambda);