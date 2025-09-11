function F = uq_ks_cdf(X, parameters, varargin)
% F = UQ_KS_CDF(X, parameters, Options) calculates the Cumulative 
%     Density Function value of samples X  whose density was estimated from
%     existing by kernel-smoothing. This is achieved by interpolating the CDF
%     values given the ones that were used for kernel-smoothing.
%
% See also: UQ_KS_PDF,UQ_KS_INVCDF 

%% everything outside the bounds is mapped to the bounds for stability
X(X<min(parameters.ucdf)) = min(parameters.ucdf);
X(X>max(parameters.ucdf)) = max(parameters.ucdf);

%% calculate the CDF values via interpolation
F = interp1(parameters.ucdf, parameters.cdf, X);


