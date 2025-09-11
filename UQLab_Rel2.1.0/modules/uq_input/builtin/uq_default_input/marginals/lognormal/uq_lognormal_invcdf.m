function X = uq_lognormal_invcdf( F, parameters )
% UQ_LOGNORMAL_INVCDF(F, parameters) calculates the inverse Cumulative 
% Density Function values of CDF values F of samples X  that follow  
% a Lognormal distribution with parameters specified in the vector
%  'parameters'

X = logninv(F, parameters(1), parameters(2));

