function F = uq_laplace_cdf( X, Parameters )
% UQ_LAPLACE_CDF(X, parameters) calculates the Cumulative Density Function
% values of samples X  that follow a Laplace distribution with parameters 
% specified in the vector 'parameters'

m = Parameters(1);
b = Parameters(2);

F = zeros(size(X));
%% set the CDF to the appropriate value for X < m
idx = X < m ;
F(idx) = 1/2*exp((X(idx)-m)./b);
%% set the CDF to the appropriate value for X >= m 
idx = X >= m ;
F(idx) = 1-1/2*exp(-(X(idx)-m)./b);
