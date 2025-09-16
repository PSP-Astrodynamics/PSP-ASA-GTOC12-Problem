function X = uq_gaussian_invcdf( F, parameters )
% UQ_GAUSSIAN_INVCDF(F, parameters) calculates the inverse Cumulative Density Function
% values of CDF values F of samples X  that follow a Gaussian distribution with 
% parameters specified in the vector 'parameters'

 X = norminv(F, parameters(1),parameters(2));


