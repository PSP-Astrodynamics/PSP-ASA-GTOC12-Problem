function lf = uq_LF_U(gmean, gsigma)
% UQ_LF_U computes the U-function for AK-MCS
% 
% References:
%
%     Echard et al., 2011. AK-MCS: an active learning reliability method
%     combining Kriging and Monte Carlo simulation. Structural Safety 33(2),
%     145-154 http://dx.doi.org/10.1016/j.strusafe.2011.01.002
%
% See also: UQ_AKMCS


lf = -abs(gmean ./ gsigma);