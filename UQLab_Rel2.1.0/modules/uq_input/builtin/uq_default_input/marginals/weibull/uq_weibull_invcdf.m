function X = uq_weibull_invcdf( F, parameters )
% UQ_WEIBULL_INVCDF(F, parameters) calculates the inverse Cumulative 
% Density Function values of CDF values F of samples X  that follow  
% a Weibull distribution with parameters specified in the vector
%  'parameters'

X =  wblinv(F, parameters(1) * ones(size(F)), parameters(2));

