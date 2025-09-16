function F = uq_gumbelmin_cdf( X, parameters )
% UQ_GUMBELMIN_CDF(X, parameters) calculates the Cumulative Density Function
% values of samples X  that follow a minimum Gumbel distribution with parameters 
% specified in the vector 'parameters'
%
% NOTE: This function refers to the *minimum* Gumbel distribution. For more
% information please refer to the UQLab user manual: The Input module. 

F = evcdf(X, parameters(1), parameters(2));