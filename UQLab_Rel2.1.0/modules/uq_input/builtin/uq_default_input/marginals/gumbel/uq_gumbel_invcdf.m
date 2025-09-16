function X = uq_gumbel_invcdf( F, parameters )
% UQ_GUMBEL_INVCDF(F, parameters) calculates the inverse Cumulative 
% Density Function values of CDF values F of samples X  that follow  
% a Gumbel distribution with parameters specified in the vector
%  'parameters'
%
% NOTE: This function refers to the *maximum* Gumbel distribution. For more
% information please refer to the UQLab user manual: The Input module. 

X = -evinv(1-F, -parameters(1), parameters(2));

