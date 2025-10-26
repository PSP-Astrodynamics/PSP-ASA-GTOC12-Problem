function F = uq_rayleigh_cdf( X, parameters )
% UQ_RAYLEIGH_CDF(X, parameters) calculates the Cumulative Density Function
% values of samples X that follow a rayleigh distribution with parameters 
% specified in the vector 'parameters'
%
F = raylcdf(X, parameters(:,1));