function X = uq_gamma_invcdf( F, parameters )
% UQ_GAMMA_INVCDF(F, parameters) calculates the inverse Cumulative Density Function
% values of CDF values F of samples X  that follow a Gamma distribution with 
% parameters specified in the vector 'parameters'
%
% Input parameters:
%
%     'X'             The samples
%
%     'parameters'    contains [lambda, k]
%
%
% NOTE: 
% Please keep in mind the differences in the notation of the parameters
% between MATLAB and UQLab
% MATLAB notation : invcdf = Finv(x|a,b)
% UQLab notation  : invcdf = Finv(x|lambda,k) , lambda = 1/b , k=a
%
% See also GAMINV
lambda = parameters(1);
k = parameters(2);

X = gaminv(F, k, 1/lambda);


