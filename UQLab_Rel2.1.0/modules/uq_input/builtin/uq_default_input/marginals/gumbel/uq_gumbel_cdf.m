function F = uq_gumbel_cdf( X, parameters )
% UQ_GUMBEL_CDF(X, parameters) calculates the Cumulative Density Function
% values of samples X  that follow a Gumbel distribution with parameters 
% specified in the vector 'parameters'
%
% NOTE: This function refers to the *maximum* Gumbel distribution. For more
% information please refer to the UQLab user manual: The Input module. 
F = 1 - evcdf(-X, -parameters(1), parameters(2));