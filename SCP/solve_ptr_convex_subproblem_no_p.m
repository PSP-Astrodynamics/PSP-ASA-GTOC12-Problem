function [x_sol, u_sol, sol_info] = solve_ptr_convex_subproblem_no_p(prob, ptr_ops, x_ref, u_ref)
%SOLVE_PTR_CONVEX_SUBPROBLEM Summary of this function goes here
%   Detailed explanation goes here

t_k = linspace(0, prob.tf, prob.N);

cvx_begin quiet
    variable X(prob.n.x, prob.N)
    variable U(prob.n.u, prob.Nu)
    variable eta(1, prob.Nu)
    variable V(prob.n.x, prob.N - 1)
    variable v_prime(prob.n.ncvx)
    variable v_0(prob.n.x, 1)
    variable v_N(prob.n.x, 1)
    minimize( prob.objective(prob.unscale_x(X), prob.unscale_u(U), 0) ...
        + virtual_control_cost(V, v_prime, v_0, v_N, ptr_ops.w_vc) ...
        + trust_region_cost(eta, 0, ptr_ops.w_tr, 0) )
    subject to
        % Dynamics
        if prob.u_hold == "ZOH"
            for k = 1:(prob.N - 1)
                X(:, k + 1) == prob.disc.A_k(:, :, k) * prob.unscale_x(X(:, k)) ...
                             + prob.disc.B_k(:, :, k) * prob.unscale_u(U(:, k)) ...
                             + prob.disc.c_k(:, :, k) ...
                             + V(:, k);
            end
        elseif prob.u_hold == "FOH"
            for k = 1:(prob.N - 1)
                X(:, k + 1) == prob.disc.A_k(:, :, k) * prob.unscale_x(X(:, k)) ...
                             + prob.disc.B_minus_k(:, :, k) * prob.unscale_u(U(:, k)) ...
                             + prob.disc.B_plus_k(:, :, k) * prob.unscale_u(U(:, k + 1)) ...
                             + prob.disc.c_k(:, :, k) ...
                             + V(:, k);
            end
        end

        % Constraints
        % Constraints
        for k = 1:prob.Nu
            % Convex Constraints
            for cc = 1:prob.n.cvx
                cc_k = prob.convex_constraints{cc}{1};
                if ismember(k, cc_k)
                    cvx_constraint_func = prob.convex_constraints{cc}{2};
                    cvx_constraint_func(t_k(k), prob.unscale_x(X(:, k)), prob.unscale_u(U(:, k)), 0) <= 0;
                end
            end
            % Nonconvex Constraints
            for nc = 1:prob.n.ncvx
                nc_k = prob.nonconvex_constraints{nc}{1};
                if ismember(k, nc_k)
                    ncvx_constraint_func = prob.nonconvex_constraints{nc}{2};
                    ncvx_constraint_func(t_k(k), prob.unscale_x(X(:, k)), prob.unscale_u(U(:, k)), 0, prob.unscale_x(x_ref), prob.unscale_u(u_ref), 0, k) ...
                        - v_prime(nc) <= 0;
                end
            end
        end
        v_prime >= 0;

        % Boundary Conditions
        prob.initial_bc(prob.unscale_x(X(:, 1)), 0) + v_0 == 0;
        prob.terminal_bc(prob.unscale_x(X(:, prob.N)), 0) + v_N == 0;

        % Trust Region Constraints
        %ptr_ops.alpha_x * norms(X(:, 1:prob.Nu) - x_ref(:, 1:prob.Nu), ptr_ops.q, 1) + ptr_ops.alpha_u * norms(U - u_ref, ptr_ops.q, 1) <= eta;
        ptr_ops.alpha_x * sum(sum_square(X(:, 1:prob.Nu) - x_ref(:, 1:prob.Nu))) + sum(ptr_ops.alpha_u * sum_square(U - u_ref)) <= eta;
cvx_end

if size(U,1) == 5
    figure
    
    tiledlayout(1, 3)
    nexttile
    plot3(X(1, :), X(2, :), X(3, :)); 
    grid on
    axis equal
    
    nexttile
    stairs(U(1, :)); hold on
    stairs(U(2, :)); hold on
    stairs(U(3, :)); hold on
    stairs(U(4, :)); hold off
    grid on
    
    nexttile
    stairs(rad2deg(U(5, :))); hold on
    stairs(acosd(U(1, :) ./ U(4, :)));
    grid on
end

x_sol = X;
u_sol = U;

sol_info.status = cvx_status;
sol_info.vd = V;
sol_info.vs = v_prime;
sol_info.vbc_0 = v_0;
sol_info.vbc_N = v_N;
sol_info.J = prob.objective(prob.unscale_x(X), prob.unscale_u(U), 0);
sol_info.J_tr = trust_region_cost(eta, 0, ptr_ops.w_tr, 0);
sol_info.J_vc = virtual_control_cost(V, v_prime, v_0, v_N, ptr_ops.w_vc);
sol_info.dJ = 100 * (prob.objective(prob.unscale_x(X), prob.unscale_u(U), 0) - prob.objective(prob.unscale_x(x_ref), prob.unscale_u(u_ref), 0)) / prob.objective(prob.unscale_x(x_ref), prob.unscale_u(u_ref), 0);
sol_info.dx = vecnorm(X(:, 1:prob.Nu) - x_ref(:, 1:prob.Nu), ptr_ops.q, 1);
sol_info.du = vecnorm(U - u_ref, ptr_ops.q, 1);
sol_info.dp = 0;
sol_info.eta = eta;
sol_info.eta_x = 0;
sol_info.eta_u = 0;
sol_info.eta_p = 0;
end

function [J_tr] = trust_region_cost(eta, eta_p, w_tr, w_tr_p)
    J_tr = w_tr * eta' + w_tr_p * eta_p;
end

function [J_vc] = virtual_control_cost(V, v_prime, v_0, v_N, w_vc)
    J_vc = w_vc * (norm(v_prime, 1) + sum(norms(V, 1, 1)) + norm(v_0, 1) + norm(v_N, 1));
end