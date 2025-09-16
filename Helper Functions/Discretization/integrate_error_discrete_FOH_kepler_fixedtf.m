function [A_k, B_k_plus, B_k_minus, S_k, d_k, x] = integrate_error_discrete_FOH_kepler_fixedtf(x0, u, s, tspan)
    % Integrates STM and state with Bk+, Bk-, and ck
    %   Uses RK4 to integrate the State Transition Matrix and the state using
    %   the given A matrix and dynamics f over the time period in tspan

    % Create initial condition
    nx = 7;
    nu = 3;
    np = numel(s);

    STM0 = eye(nx);
    B0 = zeros(nx, nu);
    S0 = zeros(nx, np);

    y0 = [x0; STM0(:); B0(:); B0(:); S0(:)];

    % Simulate    
    [y] = ode4_kepler_fixedtf(y0, tspan, u, s, nx, nu, np);
    y_f = y(end, :);

    % Unpack solution
    x = y_f(:, 1:nx)';

    A_k = reshape(y_f(:, (nx + 1) : (nx * (nx + 1))), nx, nx);
    B_k_plus = reshape(y_f(:, (nx * (nx + 1) + 1) : (nx * (nx + 1) + nx * nu)), nx, nu);
    B_k_minus = reshape(y_f(:, (nx * (nx + 1) + nx * nu + 1) : (nx * (nx + 1) + 2 * nx * nu)), nx, nu);
    S_k = reshape(y_f(:, (nx * (nx + 1) + 2 * nx * nu + 1) : (nx * (nx + 1) + 2 * nx * nu + nx * np)), nx, np);
    
    d_k = x - (A_k * x0 + B_k_minus * u(:, 1) + B_k_plus * u(:, 2) + zero_if_empty(S_k * s));
end

function ydot = STM_diff_eq_FOH(t, y, u, s, sigma_plus, sigma_minus, nx, nu, np)
    x = y(1:nx);
    STM = reshape(y((nx + 1) : (nx * (nx + 1))), nx, nx);

    Phi_B_plus = reshape(y((nx * (nx + 1) + 1) : (nx * (nx + 1) + nx * nu)), nx, nu);
    Phi_B_minus = reshape(y((nx * (nx + 1) + nx * nu + 1) : (nx * (nx + 1) + 2 * nx * nu)), nx, nu);
    Phi_S = reshape(y((nx * (nx + 1) + 2 * nx * nu + 1) : (nx * (nx + 1) + 2 * nx * nu + nx * np)), nx, np);

    u = u(:, 1) * sigma_minus + u(:, 2) * sigma_plus;

    A_t = A_kepler_fixedtf(t, x, u, s);
    B_t = B_kepler_fixedtf(t, x, u, s);

    xdot = f_kepler_fixedtf(t, x, u, s);
    A_kdot = A_t * STM;
    B_k_plusdot = A_t * Phi_B_plus + B_t * sigma_plus;
    B_k_minusdot = A_t * Phi_B_minus + B_t * sigma_minus;
    S_kdot = A_t * Phi_S + S_kepler_fixedtf(t, x, u, s);

    ydot = [xdot; A_kdot(:); B_k_plusdot(:); B_k_minusdot(:); S_kdot(:)];
end

function [Y] = ode4_kepler_fixedtf(y0, tspan, u, s, nx, nu, np)
    neq = length(y0);
    N = length(tspan);
    Y = zeros(neq,N);
    F = zeros(neq,4);
    
    Y(:,1) = y0;
    ti = tspan(1);
    hi = tspan(2) - tspan(1);
    yi = Y(:,1);
    
    sigma_plus_1 = 0;
    sigma_minus_1 = 1;
    sigma_plus_2 = 0.5;
    sigma_minus_2 = 0.5;
    sigma_plus_3 = 1;
    sigma_minus_3 = 0;
    
    F(:,1) = STM_diff_eq_FOH(ti, yi, u, s, sigma_plus_1, sigma_minus_1, nx, nu, np);
    F(:,2) = STM_diff_eq_FOH(ti + 0.5 * hi, yi + 0.5 * hi * F(:, 1), u, s, sigma_plus_2, sigma_minus_2, nx, nu, np);
    F(:,3) = STM_diff_eq_FOH(ti + 0.5 * hi, yi + 0.5 * hi * F(:, 2), u, s, sigma_plus_2, sigma_minus_2, nx, nu, np);
    F(:,4) = STM_diff_eq_FOH(tspan(2), yi + hi * F(:, 3), u, s, sigma_plus_3, sigma_minus_3, nx, nu, np);
    Y(:,2) = yi + (hi/6)*(F(:,1) + 2*F(:,2) + 2*F(:,3) + F(:,4));
    Y = Y'; % not necessary but it is what ODE45 does and code for extracting outputs was made for that
end