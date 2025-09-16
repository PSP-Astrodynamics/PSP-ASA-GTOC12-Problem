function   crossing_values  = uq_zerocrossings (y)
% retval = UQ_ZEROCROSSINGS(y)
%   This will return according to linear interpolation the "indices" where 
%   zero crossing occurs for y. The points where y==0 are not reported as
%   zero crossings.

y_aug = [y(1);y(:)];

y_sign_diff = abs(diff((y_aug>0)-(y_aug<0)));
% the indices where y_sign_diff is not zero, are the y - upper indices of 
% the zero crossing occured. When y maintains sign, y_sign_diff is zero.

% This will ignore zeros (and report only zero crossings) - pure zeros are
% at == 1.
y_cross_down = find(y_sign_diff == 2);
% perform linear interpolation to report the "y" value:
crossing_values = y_cross_down +abs(y_aug(y_cross_down))./abs(y_aug(y_cross_down+1) - y_aug(y_cross_down))-1;


% IMPROVEMENT: Use external crossing estimations For Borgonovo indices,
% the "crossings" are expected to vary smoothly along the expectation value
% integral (external integration) - this might improve accuracy with
% negligible computational cost.

