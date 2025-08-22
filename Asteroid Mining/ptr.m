function [ptr_sol] = ptr(prob, ptr_ops, parser)
%PTR Sequential Convex Programming algorithm
%   If converged, solution satisfies the nonlinear continuous-time equations of motion
% to within a tolerance on the order of eps_feasible feasible, satisfies all algebraic constraints at each
% temporal node, and approximates (local) optimality of the original optimal control problem.
arguments
    prob 
    ptr_ops 
    parser string {mustBeMember(parser, ["CVX", "CVXPY"])} = "CVX"
end

x_ref = zeros([prob.n.x, prob.N, ptr_ops.iter_max + 1]);
u_ref = zeros([prob.n.u, prob.Nu, ptr_ops.iter_max + 1]);
p_ref = zeros([prob.n.p, ptr_ops.iter_max + 1]);

x_ref(:, :, 1) = prob.scale_x(prob.guess.x);
u_ref(:, :, 1) = prob.scale_u(prob.guess.u);
p_ref(:, 1) = prob.scale_p(prob.guess.p);

ptr_sol.converged = false;
ptr_sol.objective = zeros([1, ptr_ops.iter_max + 1]);
ptr_sol.Delta = zeros([prob.n.x, prob.N + 1, ptr_ops.iter_max + 1]);
ptr_sol.delta_xp = zeros([1, ptr_ops.iter_max]);

problem = [];

% Convexify along initial guess
[prob, ptr_sol.Delta(:, :, 1)] = convexify_along_reference(prob, prob.guess.x, prob.guess.u, prob.guess.p);

disp(" k |       status      |   vd  |   vs  |  vbc_0 |  vbc_N |    J    |   J_tr  |   J_vc   |   dJ %  |   dx   |   du   |   dp   | delta |  dyn  |  eta  | eta_x | eta_u | eta_p")

for i = 1:(ptr_ops.iter_max)
    % Solve convex subproblem and update reference
    if prob.n.p == 0
        if parser == "CVX"
            [x_ref(:, :, i + 1), u_ref(:, :, i + 1), sol_info] = solve_ptr_convex_subproblem_no_p(prob, ptr_ops, x_ref(:, :, i), u_ref(:, :, i));
        elseif parser == "CVXPY"
            %[x_ref_CVX, u_ref_CVX, sol_info_CVX] = solve_ptr_convex_subproblem_no_p(prob, ptr_ops, x_ref(:, :, i), u_ref(:, :, i));
    
            [x_ref(:, :, i + 1), u_ref(:, :, i + 1), sol_info, problem] = solve_ptr_convex_subproblem_no_p_CVXPY(prob, ptr_ops, x_ref(:, :, i), u_ref(:, :, i), problem);

            %figure
            %comparison_plot_3DoF_trajectory({x_ref(:, :, i + 1), x_ref_CVX}, ["CVXPY", "CVX"], prob.params(4))
        end
    else
        [x_ref(:, :, i + 1), u_ref(:, :, i + 1), p_ref(:, i + 1), sol_info] = solve_ptr_convex_subproblem(prob, ptr_ops, x_ref(:, :, i), u_ref(:, :, i), p_ref(:, i));
    end

    % Convexify along reference trajectory
    [prob, ptr_sol.Delta(:, :, i + 1)] = convexify_along_reference(prob, prob.unscale_x(x_ref(:, :, i + 1)), prob.unscale_u(u_ref(:, :, i + 1)), prob.unscale_p(p_ref(:, i + 1)));

    % Update algorithm weights (4.24)
    ptr_ops.w_tr = update_trust_region_weights(vecnorm(ptr_sol.Delta(:, 2:(prob.Nu + 1), i + 1)), ptr_ops.update_w_tr, ptr_ops.w_tr, ptr_ops.Delta_min);

    % Check stopping criteria (4.30)
    ptr_sol.delta_xp(i) = ptr_stopping(x_ref(:, :, i + 1), p_ref(:, i + 1), x_ref(:, :, i), p_ref(:, i), ptr_ops.q);

    % Display results of iteration
    if i ~= 1
        ptr_sol.info(i).dJ = ptr_sol.info(i - 1);
    end
    sol_info.delta = ptr_sol.delta_xp(i);
    sol_info.dyn = sum(vecnorm(ptr_sol.Delta(:, :, i + 1))) <= ptr_ops.Delta_min;
    if sol_info.dyn
        dyn_str = string(sol_info.dyn);
    else
        dyn_str = sum(vecnorm(ptr_sol.Delta(:, :, i + 1)));
    end

    ptr_sol.info(i) = sol_info;

    if i == 1
        fprintf("%2.f | %17s | %5.1g | %5.1g | %5.1g | %5.1g | %5.3g | %5.3g | %5.3g |         | %6.1g | %6.1g | %5.1g | %5.1g | %5s | %5.1g | %5.1g | %5.1g | %5.1g\n", i, ptr_sol.info(i).status, norm(ptr_sol.info(i).vd), norm(ptr_sol.info(i).vs), norm(ptr_sol.info(i).vbc_0), norm(ptr_sol.info(i).vbc_N), ptr_sol.info(i).J, ptr_sol.info(i).J_tr, ptr_sol.info(i).J_vc, sum(ptr_sol.info(i).dx), sum(ptr_sol.info(i).du), sum(ptr_sol.info(i).dp), ptr_sol.info(i).delta, dyn_str, norm(ptr_sol.info(i).eta), norm(ptr_sol.info(i).eta_x), norm(ptr_sol.info(i).eta_u), norm(ptr_sol.info(i).eta_p))
    else
        fprintf("%2.f | %17s | %5.1g | %5.1g | %5.1g | %5.1g | %5.3g | %5.3g | %5.3g | %6.3f | %6.1g | %6.1g | %5.1g | %5.1g | %5s | %5.1g | %5.1g | %5.1g | %5.1g\n", i, ptr_sol.info(i).status, norm(ptr_sol.info(i).vd), norm(ptr_sol.info(i).vs), norm(ptr_sol.info(i).vbc_0), norm(ptr_sol.info(i).vbc_N), ptr_sol.info(i).J, ptr_sol.info(i).J_tr, ptr_sol.info(i).J_vc, ptr_sol.info(i).dJ, sum(ptr_sol.info(i).dx), sum(ptr_sol.info(i).du), sum(ptr_sol.info(i).dp), ptr_sol.info(i).delta, dyn_str, norm(ptr_sol.info(i).eta), norm(ptr_sol.info(i).eta_x), norm(ptr_sol.info(i).eta_u), norm(ptr_sol.info(i).eta_p))
    end

    if i >= ptr_ops.iter_min && ptr_sol.delta_xp(i) < ptr_ops.delta_tol && ~ptr_sol.converged && sol_info.dyn
        ptr_sol.converged = true;
        ptr_sol.converged_i = i;

        break
    end
end

if ptr_sol.converged == false
    warning("PTR did not converge after %g iterations. delta_xp = %.3f. norm(Delta) = %.3f\n", i, ptr_sol.delta_xp(i), sum(vecnorm(ptr_sol.Delta(:, :, end))))
end

ptr_sol.x = prob.unscale_x(x_ref);
ptr_sol.u = prob.unscale_u(u_ref);
ptr_sol.p = prob.unscale_p(p_ref);
end

function [w_tr] = update_trust_region_weights(Delta, update, w_tr, Delta_min)
    w_tr_update = 1 ./ abs(Delta) .* (abs(Delta) >= Delta_min) ...
             + 1 / Delta_min * (abs(Delta) < Delta_min);

    w_tr = update .* w_tr_update + ~update .* w_tr;
end

function [delta_xp] = ptr_stopping(X, p, x_ref, p_ref, q)
    delta_xp = zero_if_empty(vecnorm(p - p_ref, q, 1)) + max(vecnorm(X - x_ref, q, 1));
end