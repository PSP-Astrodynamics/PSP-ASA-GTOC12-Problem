function X = uq_ks_invcdf( F, parameters,varargin)
% X = UQ_KS_INVCDF(F, parameters) calculates the inverse 
%     Cumulative Density Function values of CDF values F of samples X whose
%     density was estimated from existing data by kernel-smoothing. This is
%     achieved by interpolating the already existing values. 
%
% See also: UQ_KS_PDF,UQ_KS_CDF 

%% everything outside the bounds is mapped to the bounds for stability
F(F<min(parameters.cdf)) = min(parameters.cdf);
F(F>max(parameters.cdf)) = max(parameters.cdf);

%% calculate the inverse CDF via interpolation
X = interp1(parameters.cdf, parameters.ucdf, F);