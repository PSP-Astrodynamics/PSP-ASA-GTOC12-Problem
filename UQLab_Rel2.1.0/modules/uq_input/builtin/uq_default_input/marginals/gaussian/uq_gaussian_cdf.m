function F = uq_gaussian_cdf( X, parameters )
% UQ_GAUSSIAN_CDF(X, parameters) calculates the Cumulative Density Function
% values of samples X  that follow a Gaussian distribution with parameters 
% specified in the vector 'parameters'

F = normcdf(X, parameters(1),parameters(2));



