addpath(genpath(pwd));

%% Initialize
u_max = 0.1;
mu = 1;
mu_dim = 1.327e11;
AU = 149597898;
m0 = 1;
tf = 15;
N = 30;
velocity_nd = sqrt(mu_dim/AU);

%% Earth data
a_earth = 1.49579e8 / AU;
e_earth = 1.65519e-2;
inc_earth = 4.64389e-3;
Omega_earth = 1.98956e2;
omega_earth = 2.62960e2;
M_earth0 = deg2rad(3.58040e2);
M_earth = @(t) sqrt(mu / a_earth^3) * t + M_earth0;
E_earth = @(t) mean_to_eccentric_anomaly(M_earth(t), e_earth);
nu_earth = @(t) rad2deg(eccentric_to_true_anomaly(E_earth(t), e_earth));

%% Asteroid data
a_ast = 3.073;
e_ast = 1.177e-1;
inc_ast = 17.45;
Omega_ast = 14.03;
omega_ast = 1.830;
M_ast0 = deg2rad(305.3);
M_ast = @(t) sqrt(mu / a_ast^3) * t + M_ast0;
E_ast = @(t) mean_to_eccentric_anomaly(M_ast(t), e_ast);
nu_ast = @(t) eccentric_to_true_anomaly(E_ast(t), e_ast);

%% Initial conditions
x_keplerian_earth = @(t) [a_earth e_earth inc_earth*pi/180 Omega_earth*pi/180 omega_earth*pi/180 M_earth(t)]';
x_cartesian_earth = @(t) keplerian_to_cartesian(x_keplerian_earth(t), [], mu);
x_keplerian_ast = @(t) [a_ast e_ast inc_ast*pi/180 Omega_ast*pi/180 omega_ast*pi/180 M_ast(t)]';
x_cartesian_ast = @(t) keplerian_to_cartesian(x_keplerian_ast(t), [], mu);

t_plot = linspace(0, tf, 100);
x_cartesian_earth_plot = zeros([6, numel(t_plot)]);
x_cartesian_ast_plot = zeros([6, numel(t_plot)]);
for k = 1:numel(t_plot)
    x_cartesian_earth_plot(:, k) = x_cartesian_earth(t_plot(k));
    x_cartesian_ast_plot(:, k) = x_cartesian_ast(t_plot(k));
end

x_earth0 = x_cartesian_earth(0);
r0 = x_earth0(1:3); v0 = x_earth0(4:6);
v_earth0 = x_earth0(4:6);
x_0 = [r0; v0; m0];
x_f = x_cartesian_ast(tf);

tspan = [0, tf];
t_k = linspace(tspan(1), tspan(2), N);
delta_t = t_k(2) - t_k(1);

u_hold = "ZOH";
Nu = (u_hold == "ZOH") * (N - 1) + (u_hold == "FOH") * N;

parser = "CVX";
nx = 7;
nu = 3;
np = 3;

initial_guess = "straight line";

ptr_ops.iter_max = 80;
ptr_ops.iter_min = 2;
ptr_ops.Delta_min = 1e-5;
ptr_ops.w_vc = 1e4;
ptr_ops.w_tr = ones(1, Nu) * 5e-3;
ptr_ops.w_tr_p = 1e-2 * ones(1, np);
ptr_ops.update_w_tr = false;
ptr_ops.delta_tol = 6e-3;
ptr_ops.q = 2;
ptr_ops.alpha_x = 1;
ptr_ops.alpha_u = 1;
ptr_ops.alpha_p = 0;

scale = false;

f = @(t, x, u, p) dynamics(t, x, u);

max_thrust_constraint = {1:N, @(t, x, u, p) norm(u, 2) - u_max};
v_max_nd = 6 / velocity_nd;
departure_velocity_constraint = {1, @(t, x, u, p) norm(p(1:3)) - v_max_nd};

convex_constraints = {max_thrust_constraint, departure_velocity_constraint};

initial_bc = @(x, p) [x(1:3) - x_0(1:3); x(4:6) - p(1:3) - x_0(4:6); x(7) - m0];
terminal_bc = @(x, p) [x(1:6) - x_f; 0];

if u_hold == "ZOH"
    min_fuel_objective = @(x, u, p, x_ref, u_ref, p_ref) sum(norms(u, 2, 1)) * delta_t;
else
    min_fuel_objective = @(x, u, p) sum((u(3, 1:(end - 1)) + u(3, 2:end)) / 2) * delta_t;
end

AU_guess = interp1(tspan, [a_earth, a_ast]', t_k);
nu_guess = interp1(tspan, [nu_earth(0), nu_ast(tf)]', t_k);
r_guess = [AU_guess .* cos(nu_guess); AU_guess .* sin(nu_guess)];
r_guess(end + 1, :) = 0;
v_guess = v_circ(r_guess, nu_guess, mu);
v_guess(end + 1, :) = 0;
m_guess = ones(1, N);

guess.x = [r_guess; v_guess; m_guess];
guess.u = interp1(tspan, ones(3, 2)' * 1e-5, t_k(1:Nu))';
guess.p = [0; 0; 0];

problem = DeterministicProblem(x_0, x_f, N, u_hold, tf, f, guess, convex_constraints, min_fuel_objective, scale = scale, initial_bc = initial_bc, terminal_bc = terminal_bc, integration_tolerance = 1e-12, discretization_method = "state", N_sub = 1);

[problem, Delta_disc] = problem.discretize(guess.x, guess.u, guess.p);
ptr_sol = ptr(problem, ptr_ops, parser);

%%
if ~ptr_sol.converged
    ptr_sol.converged_i = ptr_ops.iter_max;
end

i = ptr_sol.converged_i + 1;
x = ptr_sol.x(:, :, i);
u = ptr_sol.u(:, :, i);
p = ptr_sol.p(:, i);
r = x(1:3, :); v = x(4:6, :);

x_0_opt = x_0 + [0; 0; 0; p(1:3); 0];

[t_cont_sol, x_cont_sol, u_cont_sol] = problem.cont_prop(ptr_sol.u(:, :, i), ptr_sol.p(:, i), x0 = x_0_opt);
r_cont_sol = x_cont_sol(1:3, :);
v_cont_sol = x_cont_sol(4:6, :);
%%
figure
plot_cartesian_orbit(r_cont_sol(1:3,:)', 'k', 0.4, 1); hold on
quiver3(r(1, 1:Nu), r(2, 1:Nu), r(3, 1:Nu), u(1, :), u(2, :), u(3, :), 1, "filled", Color = "red")
plot_cartesian_orbit(r_guess(1:3,:)', 'g', 0.4, 1); hold on
plot_cartesian_orbit(x_cartesian_earth_plot(1:3, :)', 'b', 0.3, 1)
plot_cartesian_orbit(x_cartesian_ast_plot(1:3, :)', 'cyan', 0.3, 1)
scatter3(x_cartesian_earth_plot(1, 1), x_cartesian_earth_plot(2, 1), x_cartesian_earth_plot(3, 1), "green")
scatter3(x_cartesian_ast_plot(1, end), x_cartesian_ast_plot(2, end), x_cartesian_ast_plot(3, end), "red")
title('Optimal Transfer Trajectory')
xlabel('x (AU)'); ylabel('y (AU)')
legend('Spacecraft', "", "Thrust", 'Guess', "", 'Earth', "", 'Asteroid', "", "Start", "End", 'Location', 'northwest'); axis equal; grid on

%%
figure
tiledlayout(1, 2)

nexttile
plot(t_cont_sol(1:end - 1), u_cont_sol(1:3,:)); hold on
plot(t_cont_sol(1:end - 1), vecnorm(u_cont_sol(1:3,:)))
title("Control")
xlabel("Time")

nexttile
plot(t_cont_sol(1:end), x_cont_sol(7, :))
title("Mass")
xlabel("Time")


%% Helper
function [v_guess] = v_circ(r_guess, nu_guess, mu)
    r = vecnorm(r_guess, 2, 1);
    v = sqrt(mu ./ r);
    v_guess = v .* [-sin(nu_guess); cos(nu_guess)];
end
