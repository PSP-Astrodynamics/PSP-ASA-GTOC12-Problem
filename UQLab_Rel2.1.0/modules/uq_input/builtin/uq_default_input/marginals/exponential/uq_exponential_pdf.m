function F = uq_exponential_pdf( X, lambda )
% UQ_EXPONENTIAL_PDF calculates the Probability Density Function
% values of samples X  that follow an exponential distribution with 
% some value of the distribution's lambda parameter
%
% NOTE: 
% Please keep in mind the differences in the notation of the parameters
% between MATLAB and UQLab
% MATLAB notation : pdf = f(x|mu)
% UQLab notation  : pdf = f(x|lambda) , lambda = 1/mu 
%
% See also EXPPDF

F = exppdf(X, 1/lambda(1));

