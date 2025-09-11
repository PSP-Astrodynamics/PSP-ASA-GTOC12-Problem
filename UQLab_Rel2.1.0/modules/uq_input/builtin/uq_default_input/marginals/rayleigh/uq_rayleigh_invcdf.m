function X = uq_rayleigh_invcdf( F, parameters )
% UQ_RAYLEIGH_INVCDF(F, parameters) calculates the inverse Cumulative 
% Density Function values of CDF values F of samples X  that follow  
% a Rayleigh distribution with parameters specified in the vector
%  'parameters'

X = raylinv(F,parameters(:,1));

