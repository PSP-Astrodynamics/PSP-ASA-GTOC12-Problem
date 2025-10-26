function [A_k, B_k, S_k, d_k, Delta] = discretize_error_dynamics_ZOH(f, A, B, S, N, tspan, x_ref, u_ref, s_ref, tolerances)
    % Discretization of the devition from a reference trajectory for a dynamical system assuming FOH control
    % Make c optional? c = f - Ax - Bu

    nx = numel(x_ref(:, 1));
    nu = numel(u_ref(:, 1));
    np = numel(s_ref);

    t_k = linspace(tspan(1), tspan(2), N);
    A_k = zeros([nx, nx, N - 1]);
    B_k = zeros([nx, nu, N - 1]);
    S_k = zeros([nx, np, N - 1]);
    d_k = zeros([nx, 1, N - 1]);
    Delta = zeros([nx, N - 1]);

    for k = 1:(N - 1)
        u_ref_k = u_ref(:, k);
        [A_k(:, :, k), B_k(:, :, k), S_k(:, :, k), d_k(:, :, k), x_kp1] = integrate_error_discrete_ZOH(x_ref(:, k), A, B, S, f, u_ref_k, s_ref, [t_k(k), t_k(k + 1)], tolerances);
        Delta(:, k) = x_kp1 - x_ref(:, k + 1);
    end
end