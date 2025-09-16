function [prob, Delta] = convexify_along_reference(prob, x_ref, u_ref, p_ref)
%CONVEXIFY_ALONG_REFERENCE Summary of this function goes here
%   Detailed explanation goes here
% Normalize - should already be right?

% Discretize
[prob, Delta] = prob.discretize(x_ref, u_ref, p_ref);

Delta = [prob.initial_bc(x_ref(:, 1), p_ref), Delta, prob.terminal_bc(x_ref(:, end), p_ref, x_ref(:, end), p_ref)];

end