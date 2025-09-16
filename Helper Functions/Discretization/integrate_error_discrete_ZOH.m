function [A_k, B_k, S_k, d_k, x] = integrate_error_discrete_ZOH(x0, A, B, S, f, u, s, tspan, tolerances)
    % Integrates STM and state with B, and ck
    %   Uses ODE45 to integrate the State Transition Matrix and the state using
    %   the given A matrix and dynamics f over the time period in tspan using
    %   the specified error tolerance.

    % Create initial condition
    nx = numel(x0);
    np = numel(s);

    STM0 = eye(nx);
    B0 = zeros(size(B(0, x0, u, s)));
    S0 = zeros(nx, np);

    nu = size(B0, 2);

    y0 = [x0; STM0(:); B0(:); S0(:)];

    tolerances = odeset(RelTol=1e-5, AbsTol=1e-5, Stats = "off", InitialStep = 1 * (tspan(2) - tspan(1)), MaxStep = 1 * (tspan(2) - tspan(1)));

    % Simulate    
    [~, y] = ode78(@(t, y) STM_diff_eq_ZOH(t, y, A, B, S, f, u, s, nx, nu, np), tspan, y0, tolerances);

    y_f = y(end, :);

    % Unpack solution
    x = y_f(:, 1:nx)';

    A_k = reshape(y_f(:, (nx + 1) : (nx * (nx + 1))), nx, nx);
    B_k = reshape(y_f(:, (nx * (nx + 1) + 1) : (nx * (nx + 1) + nx * nu)), nx, nu);
    S_k = reshape(y_f(:, (nx * (nx + 1) + nx * nu + 1) : (nx * (nx + 1) + nx * nu + nx * np)), nx, np);
    
    %d_k = x - (A_k * x0 + B_k_minus * u(tspan(1)) + B_k_plus * u(tspan(end)) + S_k * s);
    d_k = x - (A_k * x0 + B_k * u + zero_if_empty(S_k * s));
end

function ydot = STM_diff_eq_ZOH(t, y, A, B, S, f, u, s, nx, nu, np)
    x = y(1:nx);
    STM = reshape(y((nx + 1) : (nx * (nx + 1))), nx, nx);

    Phi_B = reshape(y((nx * (nx + 1) + 1) : (nx * (nx + 1) + nx * nu)), nx, nu);
    Phi_S = reshape(y((nx * (nx + 1) + nx * nu + 1) : (nx * (nx + 1) + nx * nu + nx * np)), nx, np);

    A_t = A(t, x, u, s);
    B_t = B(t, x, u, s);

    xdot = f(t, x, u, s);
    A_kdot = A_t * STM;
    B_kdot = A_t * Phi_B + B_t;
    S_kdot = A_t * Phi_S + S(t, x, u, s);

    ydot = [xdot; A_kdot(:); B_kdot(:); S_kdot(:)];
end