function F = uq_lognormal_cdf(X, parameters)
% UQ_LOGNORMAL_CDF(X, parameters) calculates the Cumulative Density Function
% values of samples X  that follow a Lognormal distribution with parameters 
% specified in the vector 'parameters'

F = logncdf(X, parameters(1), parameters(2));

