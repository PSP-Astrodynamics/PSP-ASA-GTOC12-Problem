function p = uq_TestCustomDistribution_pdf(X, parameters)
% p = uq_ExampleCustomDistribution_pdf(X, parameters)
%     PDF of a custom distribution with name ExampleCustomDistribution. 
%     Custom distributions can be defined analogously. This one, 
%     specifically, is equivalent to the Gaussian distribution.

p = uq_gaussian_pdf(X, parameters);
