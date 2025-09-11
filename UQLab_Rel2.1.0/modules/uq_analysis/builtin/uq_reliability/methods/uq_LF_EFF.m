function lf = uq_LF_EFF(gmean, gsigma)
% UQ_LF_EFF computes the EFF-function for AK-MCS
%
% References:
%
%     Bichon, Barron J., et al. 
%     Efficient global reliability analysis for nonlinear implicit 
%     performance functions. AIAA journal 46.10 (2008): 2459-2468.
%     http://arc.aiaa.org/doi/abs/10.2514/1.34321
%
% See also: UQ_AKMCS


eps = 2*gsigma;
lf = gmean .*  ( 2*normcdf(-gmean./gsigma, 0, 1) - normcdf(-(eps+gmean)./gsigma, 0, 1) - normcdf((eps-gmean)./gsigma, 0, 1))...
    -gsigma .* ( 2*normpdf(-gmean./gsigma, 0, 1) - normpdf(-(eps+gmean)./gsigma, 0, 1) - normpdf((eps-gmean)./gsigma, 0, 1))...
    +eps .* ( normcdf((eps-gmean)./gsigma, 0, 1) - normcdf((-eps-gmean)./gsigma, 0, 1));