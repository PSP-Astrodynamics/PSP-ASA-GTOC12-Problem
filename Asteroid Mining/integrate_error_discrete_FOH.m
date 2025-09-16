function [A_k, B_k_plus, B_k_minus, S_k, d_k, x] = integrate_error_discrete_FOH(x0, A, B, S, f, u, s, tspan, tolerances)
    % Integrates STM and state with Bk+, Bk-, and ck
    %   Uses ODE45 to integrate the State Transition Matrix and the state using
    %   the given A matrix and dynamics f over the time period in tspan using
    %   the specified error tolerance.

    % Create initial condition
    nx = numel(x0);
    np = numel(s);

    STM0 = eye(nx);
    B0 = zeros(size(B(0, x0, u(:, 1), s)));%u(tspan(1)))));
    S0 = zeros(nx, np);

    nu = size(B0, 2);

    y0 = [x0; STM0(:); B0(:); B0(:); S0(:)];

    % Set up linear interpolation functions
    sigma_plus = @(t) (t - tspan(1)) ./ (tspan(2) - tspan(1));
    sigma_minus = @(t) (tspan(2) - t) ./ (tspan(2) - tspan(1));

    tolerances = odeset(RelTol=1e-3, AbsTol=1e-3, Stats = "off", InitialStep = 1 * (tspan(2) - tspan(1)), MaxStep = 1 * (tspan(2) - tspan(1)));

    % Simulate    
    [~, y] = ode45(@(t, y) STM_diff_eq_FOH(t, y, A, B, S, f, u, s, sigma_plus, sigma_minus, nx, nu, np), tspan, y0, tolerances);
    %[y] = ode4(@(t, y) STM_diff_eq_FOH(t, y, A, B, S, f, u, s, sigma_plus, sigma_minus, nx, nu, np), tspan, y0);

    y_f = y(end, :);

    % Unpack solution
    x = y_f(:, 1:nx)';

    A_k = reshape(y_f(:, (nx + 1) : (nx * (nx + 1))), nx, nx);
    B_k_plus = reshape(y_f(:, (nx * (nx + 1) + 1) : (nx * (nx + 1) + nx * nu)), nx, nu);
    B_k_minus = reshape(y_f(:, (nx * (nx + 1) + nx * nu + 1) : (nx * (nx + 1) + 2 * nx * nu)), nx, nu);
    S_k = reshape(y_f(:, (nx * (nx + 1) + 2 * nx * nu + 1) : (nx * (nx + 1) + 2 * nx * nu + nx * np)), nx, np);
    
    %d_k = x - (A_k * x0 + B_k_minus * u(tspan(1)) + B_k_plus * u(tspan(end)) + S_k * s);
    d_k = x - (A_k * x0 + B_k_minus * u(:, 1) + B_k_plus * u(:, 2) + zero_if_empty(S_k * s));
end

function ydot = STM_diff_eq_FOH(t, y, A, B, S, f, u, s, sigma_plus, sigma_minus, nx, nu, np)
    x = y(1:nx);
    STM = reshape(y((nx + 1) : (nx * (nx + 1))), nx, nx);

    Phi_B_plus = reshape(y((nx * (nx + 1) + 1) : (nx * (nx + 1) + nx * nu)), nx, nu);
    Phi_B_minus = reshape(y((nx * (nx + 1) + nx * nu + 1) : (nx * (nx + 1) + 2 * nx * nu)), nx, nu);
    Phi_S = reshape(y((nx * (nx + 1) + 2 * nx * nu + 1) : (nx * (nx + 1) + 2 * nx * nu + nx * np)), nx, np);

    u = u(:, 1) * sigma_minus(t) + u(:, 2) * sigma_plus(t);

    A_t = A(t, x, u, s);
    B_t = B(t, x, u, s);

    xdot = f(t, x, u, s);
    A_kdot = A_t * STM;
    B_k_plusdot = A_t * Phi_B_plus + B_t * sigma_plus(t);
    B_k_minusdot = A_t * Phi_B_minus + B_t * sigma_minus(t);
    S_kdot = A_t * Phi_S + S(t, x, u, s);

    ydot = [xdot; A_kdot(:); B_k_plusdot(:); B_k_minusdot(:); S_kdot(:)];
end