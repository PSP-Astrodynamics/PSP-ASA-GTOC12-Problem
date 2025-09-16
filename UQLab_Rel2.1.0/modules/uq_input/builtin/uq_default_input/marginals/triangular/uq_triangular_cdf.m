function F = uq_triangular_cdf( X, parameters )
% UQ_TRIANGULAR_CDF(X, PARAMETERS) calculates the Cumulative Density Function
% values of samples X  that follow a triangular distribution with parameters 
% specified in the vector 'parameters'
% PARAMETERS = [a, b, peak] is a vector containing lower bound, upper bound
% and peak location

a = parameters(1); % lower bound
b = parameters(2); % upper bound
c = parameters(3); % peak

% return an error if c is not within the range
if c > b || c < a
    error('Error in uq_triangular_cdf: peak value specified is outside distribution bounds')
end

F = zeros(size(X));

%% set the CDF to 0 below the lower bound
idx = X <= a;
F(idx) = 0;

%% set the CDF to the appropriate value in the valid range
idx = X > a & X < c ;
F(idx) = (X(idx) - a).^2 /(b-a)/(c-a);
idx = X > c & X < b ;
F(idx) = 1 - (b - X(idx)).^2 /(b-a)/(b-c);

%% set the CDF to 1 above the bound 
idx = X >= b ;
F(idx) = 1;
