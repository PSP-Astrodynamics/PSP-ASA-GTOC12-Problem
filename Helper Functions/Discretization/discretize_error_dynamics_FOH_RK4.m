function [A_k, B_k_plus, B_k_minus, S_k, d_k, Delta] = discretize_error_dynamics_FOH_RK4(f, A, B, S, N, tspan, x_ref, u_ref, s_ref, N_sub)
    % Discretization of the devition from a reference trajectory for a dynamical system assuming FOH control

    nx = numel(x_ref(:, 1));
    nu = numel(u_ref(:, 1));
    np = numel(s_ref);

    t = linspace(tspan(1), tspan(2), N);
    dt = t(2) - t(1);

    A_k = zeros([nx, nx, N - 1]);
    for k = 1 : (N - 1)
        A_k(:, :, k) = eye(nx);
    end
    B_k_plus = zeros([nx, nu, N - 1]);
    B_k_minus = zeros([nx, nu, N - 1]);
    S_k = zeros([nx, np, N - 1]);
    %d_k = zeros([nx, 1, N - 1]);
    %Delta = zeros([1, N - 1]);

    %% RK4  

    t_sub_0 = t(1 : (end - 1));
    t_sub_1 = t(2 : end);

    dt_sub = (t(2) - t(1)) / N_sub;

    x_k = x_ref(:, 1 : (N - 1));

    u_sub_0 = u_ref(:, 1 : (N - 1));
    u_sub_1 = u_ref(:, 2 : N);

    for k = 1:N_sub
        t_k = t_sub_0 + dt_sub * (k - 1);

        sigma_plus_k = reshape((t_k - t_sub_0) ./ dt, 1, 1, []);
        sigma_plus_kphalf = reshape((t_k + dt_sub / 2 - t_sub_0) ./ dt, 1, 1, []);
        sigma_plus_kp1 = reshape((t_k + dt_sub - t_sub_0) ./ dt, 1, 1, []);
        
        sigma_minus_k = reshape((t_sub_1 - t_k) ./ dt, 1, 1, []);
        sigma_minus_kphalf = reshape((t_sub_1 - t_k - dt_sub / 2) ./ dt, 1, 1, []);
        sigma_minus_kp1 = reshape((t_sub_1 - t_k - dt_sub) ./ dt, 1, 1, []);

        u_k = (t_k - t_sub_0) ./ dt .* u_sub_0 ...
            + (t_sub_1 - t_k) ./ dt .* u_sub_1;
        u_kphalf = (t_k + dt_sub / 2 - t_sub_0) ./ dt .* u_sub_0 ...
                 + (t_sub_1 - t_k - dt_sub / 2) ./ dt .* u_sub_1;
        u_kp1 = (t_k + dt_sub - t_sub_0) ./ dt .* u_sub_0 ...
              + (t_sub_1 - t_k - dt_sub) ./ dt .* u_sub_1;

        [xdot_k0, A_kdot_k0, B_k_plusdot_k0, B_k_minusdot_k0, S_kdot_k0] = STM_diff_eq_FOH(t_k, x_k, A, B, S, f, u_k, s_ref, sigma_plus_k, sigma_minus_k, A_k, B_k_plus, B_k_minus, S_k);
        x_est1 = dt_sub / 2 .* xdot_k0 + x_k;
        A_k_est1 = dt_sub / 2 .* A_kdot_k0 + A_k;
        B_k_plus_est1 = dt_sub / 2 .* B_k_plusdot_k0 + B_k_plus;
        B_k_minus_est1 = dt_sub / 2 .* B_k_minusdot_k0 + B_k_minus;
        S_k_est1 = dt_sub / 2 .* S_kdot_k0 + S_k;

        [xdot_k1, A_kdot_k1, B_k_plusdot_k1, B_k_minusdot_k1, S_kdot_k1] = STM_diff_eq_FOH(t_k + dt_sub / 2, x_est1, A, B, S, f, u_kphalf, s_ref, sigma_plus_kphalf, sigma_minus_kphalf, A_k_est1, B_k_plus_est1, B_k_minus_est1, S_k_est1);
        x_est2 = dt_sub / 2 .* xdot_k1 + x_k;
        A_k_est2 = dt_sub / 2 .* A_kdot_k1 + A_k;
        B_k_plus_est2 = dt_sub / 2 .* B_k_plusdot_k1 + B_k_plus;
        B_k_minus_est2 = dt_sub / 2 .* B_k_minusdot_k1 + B_k_minus;
        S_k_est2 = dt_sub / 2 .* S_kdot_k1 + S_k;

        [xdot_k2, A_kdot_k2, B_k_plusdot_k2, B_k_minusdot_k2, S_kdot_k2] = STM_diff_eq_FOH(t_k + dt_sub / 2, x_est2, A, B, S, f, u_kphalf, s_ref, sigma_plus_kphalf, sigma_minus_kphalf, A_k_est2, B_k_plus_est2, B_k_minus_est2, S_k_est2);
        x_est3 = dt_sub / 2 .* xdot_k2 + x_k;
        A_k_est3 = dt_sub / 2 .* A_kdot_k2 + A_k;
        B_k_plus_est3 = dt_sub / 2 .* B_k_plusdot_k2 + B_k_plus;
        B_k_minus_est3 = dt_sub / 2 .* B_k_minusdot_k2 + B_k_minus;
        S_k_est3 = dt_sub / 2 .* S_kdot_k2 + S_k;

        [xdot_k3, A_kdot_k3, B_k_plusdot_k3, B_k_minusdot_k3, S_kdot_k3] = STM_diff_eq_FOH(t_k + dt_sub, x_est3, A, B, S, f, u_kp1, s_ref, sigma_plus_kp1, sigma_minus_kp1, A_k_est3, B_k_plus_est3, B_k_minus_est3, S_k_est3);

        x_kp1 = x_k + (dt_sub/6) * (xdot_k0 + 2 * xdot_k1 + 2 * xdot_k2 + xdot_k3);
        A_kp1 = A_k + (dt_sub/6) * (A_kdot_k0 + 2 * A_kdot_k1 + 2 * A_kdot_k2 + A_kdot_k3);
        B_kp1_plus = B_k_plus + (dt_sub/6) * (B_k_plusdot_k0 + 2 * B_k_plusdot_k1 + 2 * B_k_plusdot_k2 + B_k_plusdot_k3);
        B_kp1_minus = B_k_minus + (dt_sub/6) * (B_k_minusdot_k0 + 2 * B_k_minusdot_k1 + 2 * B_k_minusdot_k2 + B_k_minusdot_k3);
        S_kp1 = S_k + (dt_sub/6) * (S_kdot_k0 + 2 * S_kdot_k1 + 2 * S_kdot_k2 + S_kdot_k3);

        x_k = x_kp1;
        A_k = A_kp1;
        B_k_plus = B_kp1_plus;
        B_k_minus = B_kp1_minus;
        S_k = S_kp1;
    end

    d_k = reshape(x_kp1, nx, 1, N - 1) - (pagemtimes(A_k, reshape(x_ref(:, 1 : (N - 1)), nx, 1, N - 1)) ...
        + pagemtimes(B_k_minus, reshape(u_ref(:, 1 : (N - 1)), nu, 1, N - 1)) ...
        + pagemtimes(B_k_plus, reshape(u_ref(:, 2 : N), nu, 1, N - 1)) ...
        + zero_if_empty(pagemtimes(S_k, zero_if_empty(s_ref))));
    
    Delta = x_kp1 - x_ref(:, 2 : N);
end

function [xdot, A_kdot, B_k_plusdot, B_k_minusdot, S_kdot] = STM_diff_eq_FOH(t, x, A, B, S, f, u, s, sigma_plus, sigma_minus, STM, Phi_B_plus, Phi_B_minus, Phi_S)
    n = numel(t);

    A_t = zeros(size(STM));
    B_t = zeros(size(Phi_B_plus));
    S_t = zeros(size(Phi_S));
    xdot = zeros(size(x));
    for k = 1:n
        A_t(:, :, k) = A(t(k), x(:, k), u(:, k), s);
        B_t(:, :, k) = B(t(k), x(:, k), u(:, k), s);
        S_t(:, :, k) = S(t(k), x(:, k), u(:, k), s);
        xdot(:, k) = f(t(k), x(:, k), u(:, k), s);
    end

    A_kdot = pagemtimes(A_t, STM);
    B_k_plusdot = pagemtimes(A_t, Phi_B_plus) + B_t .* sigma_plus;
    B_k_minusdot = pagemtimes(A_t, Phi_B_minus) + B_t .* sigma_minus;
    S_kdot = pagemtimes(A_t, Phi_S) + S_t;
end