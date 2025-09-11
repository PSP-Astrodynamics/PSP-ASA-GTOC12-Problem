function F = uq_exponential_cdf( X, lambda )
%UQ_EXPONENTIAL_CDF calculates the Cumulative Density Function
% values of samples X  that follow an exponential distribution with 
% some value of the distribution's lambda parameter
%
% NOTE: 
% Please keep in mind the differences in the notation of the parameters
% between MATLAB and UQLab
% MATLAB notation : cdf = F(x|mu)
% UQLab notation  : cdf = F(x|lambda) , lambda = 1/mu 
% 
% See also EXPCDF

F = expcdf(X, 1/lambda(1));



