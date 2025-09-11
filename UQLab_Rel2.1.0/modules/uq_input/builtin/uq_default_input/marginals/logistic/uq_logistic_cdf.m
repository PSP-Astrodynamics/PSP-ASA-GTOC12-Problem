function F = uq_logistic_cdf( X, Parameters )
% UQ_LOGISTIC_CDF(X, parameters) calculates the Cumulative Density Function
% values of samples X  that follow a logistic distribution with parameters 
% specified in the vector 'parameters'

m = Parameters(1);
s = Parameters(2);

F = 1./(1+exp(-(X-m)/s));
