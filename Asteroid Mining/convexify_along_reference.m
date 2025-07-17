function [prob, Delta] = convexify_along_reference(prob, x_ref, u_ref, p_ref)
%CONVEXIFY_ALONG_REFERENCE Summary of this function goes here
%   Detailed explanation goes here
% Normalize - should already be right?

% Discretize
[prob, Delta] = prob.discretize(x_ref, u_ref, p_ref);

if numel(Delta) ~= prob.Nu
    Delta = [Delta, 0.00000001]; % Figure out what to do...
end

end