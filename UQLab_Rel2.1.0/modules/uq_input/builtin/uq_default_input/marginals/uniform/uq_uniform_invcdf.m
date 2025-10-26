function X = uq_uniform_invcdf( F, parameters )
% UQ_UNIFORM_INVCDF(F, parameters) calculates the inverse Cumulative 
% Density Function values of CDF values F of samples X  that follow  
% a uniform distribution with parameters specified in the vector
%  'parameters'

a = parameters(1);
b = parameters(2);

X = a * ones(size(F)) + (b - a) * F;



