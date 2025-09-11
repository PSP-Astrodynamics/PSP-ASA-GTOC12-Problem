function p = uq_TestCustomDistribution_invcdf(X, parameters)
% p = uq_ExampleCustomDistribution_invcdf(X, parameters)
%     Inverse CDF of a custom distribution named ExampleCustomDistribution. 
%     Custom distributions can be defined analogously. This one, 
%     specifically, is equivalent to the Gaussian distribution.

p = uq_gaussian_invcdf(X, parameters);
