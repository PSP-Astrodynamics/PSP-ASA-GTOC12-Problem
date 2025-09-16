function X = uq_triangular_invcdf(F, parameters)
% UQ_TRIANGULAR_INVCDF(F, parameters) calculates the inverse Cumulative 
% Density Function values of CDF values F of samples X  that follow  
% a triangular distribution with parameters specified in the vector
%  'parameters'
% PARAMETERS = [a, b, peak] is a vector containing lower bound, upper bound
% and peak location

a = parameters(1); % lower bound
b = parameters(2); % upper bound
c = parameters(3); % peak

% return an error if c is not within the range
if c > b || c < a
    error('Error in uq_triangular_cdf: peak value specified is outside distribution bounds')
end

X = zeros(size(F));
Fm = (c-a)/(b-a);

%% set the InvCDF to the appropriate value below Fm
idx = F <= Fm;
X(idx) = a + sqrt(F(idx) * (b-a)*(c-a));

%% set the InvCDF to the appropriate value above Fm
idx =  F > Fm ;
X(idx) = b - sqrt( (1 - F(idx))*(b-a)*(b-c));
