function X = uq_gumbelmin_invcdf( F, parameters )
% UQ_GUMBELMIN_INVCDF(F, parameters) calculates the inverse Cumulative Density Function
% values of CDF values F of samples X  that follow a minimum Gumbel distribution with 
% parameters specified in the vector 'parameters'
%
% NOTE: This function refers to the *minimum* Gumbel distribution. For more
% information please refer to the UQLab user manual: The Input module. 

X = evinv(F, parameters(1), parameters(2));

