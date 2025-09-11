function X = uq_laplace_invcdf( F, Parameters )
% UQ_LAPLACE_INVCDF(F, parameters) calculates the inverse Cumulative Density 
% Function values of CDF values F of samples X  that follow a Laplace 
% distribution with parameters specified in the vector 'parameters'

m = Parameters(1);
b = Parameters(2);

X = m - b*sign(F - 0.5) .* log(1 - 2*abs(F - 0.5));
