function [Delta] = calculate_defect(prob, x_ref, u_ref, p_ref)
%CALCULATE_DEFECT Summary of this function goes here
%   If reference state, control, and parameter vectors satisfy the
%   nonlinear dynamics, then the defects will all be zero. This means the
%   defects can probide a necessary and sufficient measure of dynamic
%   feasibility
    
    x_prop = zeros([prob.n.x, prob.N - 1]);

    if prob.u_hold == "ZOH"
        u_ref_func = @(t) interp1(prob.t_k(1:prob.Nu), u_ref(:, 1:prob.Nu)', t, "previous","extrap")';
    elseif prob.u_hold == "FOH"
        u_ref_func = @(t) interp1(prob.t_k(1:size(u_ref, 2)), u_ref', t, "linear","extrap")';
    end

    % Propagate trajectory with actual control and dynamics
    for k = 1:(prob.N - 1)
        [~, x_prop_k] = ode45(@(t, x) prob.cont.f(t, x, u_ref_func(t), p_ref), [prob.t_k(k), prob.t_k(k + 1)], x_ref(:, k), prob.tolerances);
        x_prop(:, k) = x_prop_k(end, :)';
    end
   
    Delta = vecnorm(x_prop - x_ref(:, 2:end), 2, 1);
end

