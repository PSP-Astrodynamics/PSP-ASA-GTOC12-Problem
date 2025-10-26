function p = uq_TestCustomDistribution_cdf(X, parameters)
% p = uq_TestCustomDistribution_cdf(X, parameters)
%     CDF of a custom distribution with name ExampleCustomDistribution. 
%     Custom distributions can be defined analogously. This one, 
%     specifically, is equivalent to the Gaussian distribution.

p = uq_gaussian_cdf(X, parameters);
