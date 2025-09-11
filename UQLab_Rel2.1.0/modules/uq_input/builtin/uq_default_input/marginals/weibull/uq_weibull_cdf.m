function F = uq_weibull_cdf( X, parameters )
% UQ_WEIBULL_CDF(X, parameters) calculates the Cumulative Density Function
% values of samples X  that follow a Weibull distribution with parameters 
% specified in the vector 'parameters'

F =  wblcdf(X,parameters(1) * ones(size(X)), parameters(2));
