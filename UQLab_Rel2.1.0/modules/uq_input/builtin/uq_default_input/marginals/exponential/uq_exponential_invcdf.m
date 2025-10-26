function X = uq_exponential_invcdf( F, lambda )
% UQ_EXPONENTIAL_INVCDF(F, parameters) calculates the inverse Cumulative Density Function
% values of CDF values F of samples X  that follow an exponential distribution with 
% some value of the distribution's lambda parameter
%
% NOTE: 
% Please keep in mind the differences in the notation of the parameters
% between MATLAB and UQLab
% MATLAB notation : invcdf = Finv(x|mu)
% UQLab notation  : invcdf = Finv(x|lambda) , lambda = 1/mu 
%
% See also EXPINV
 X = expinv(F, 1/lambda(1));


