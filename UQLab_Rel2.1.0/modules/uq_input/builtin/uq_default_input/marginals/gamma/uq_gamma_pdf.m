function F = uq_gamma_pdf( X, parameters )
% UQ_GAMMA_PDF(X, parameters) calculates the Probability Density Function
% values of samples X  that follow a Gamma distribution with parameters 
% specified in the vector 'parameters'
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
% MATLAB notation : pdf = f(x|a,b)
% UQLab notation  : pdf = f(x|lambda,k) , lambda = 1/b , k=a
% 
% See also GAMPDF
%
lambda = parameters(1);
k = parameters(2);

F = gampdf(X, k, 1/lambda);