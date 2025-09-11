function F = uq_uniform_cdf( X, parameters )
% UQ_UNIFORM_CDF(X, parameters) calculates the Cumulative Density Function
% values of samples X  that follow a uniform distribution with parameters 
% specified in the vector 'parameters'

F = zeros(size(X));
a =  parameters(1);
b =  parameters(2);

%% Get the indices of the elements of X that lie before between or after the bounds
ind1 = X < a;
ind2 = X > b;
ind3 = ~(ind1 | ind2);

%% set the CDF to 0 below the lower bound
F(ind1) = 0;
%% set the CDF to the appropriate value between the bounds
F(ind3) = (X(ind3) - a) / (b - a);

%% set the CDF to 1 above the bound 
F(ind2) = 1;

