%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% AAE 590ACA
% Stochastic SCP Rocket Landing Project
% Author: Travis Hastreiter 
% Created On: 6 April, 2025
% Description: 3DoF landing of rocket using PTR SCP algorithm
% Most Recent Change: 6 April, 2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
addpath(genpath(pwd));

%% Initialize
% Vehicle Parameters
u_max = 0.1;
mu = 1;
AU = 149597898;
m0 = 1;

% Problem Parameters
tf = 15; % [s]
N = 30; % []

%% Asteroid 1 data
a_ast1 = 2.015;
e_ast1 = 0.234;
inc_ast1 = 6.832;
Omega_ast1 = 168;
omega_ast1 = 216;
M0_ast1 = deg2rad(20.59);
M_ast1 = @(t) sqrt(mu/a_ast1^3)*t+M0_ast1;
E_ast1 = @(t) mean_to_eccentric_anomaly(M_ast1(t), e_ast1);
nu_ast1 = @(t) rad2deg(eccentric_to_true_anomaly(E_ast1(t), e_ast1));

%% Asteroid 2 data
a_ast2 = 3.073;
e_ast2 = 0.118;
inc_ast2 = 17.45;
Omega_ast2 = 14.03;
omega_ast2 = 1.830;
M0_ast2 = deg2rad(305.3);
M_ast2 = @(t) sqrt(mu/a_ast2^3)*t+M0_ast2;
E_ast2 = @(t) mean_to_eccentric_anomaly(M_ast2(t), e_ast2);
nu_ast2 = @(t) eccentric_to_true_anomaly(E_ast2(t), e_ast2);

%% Create initial conditions
x_keplerian_ast1 = @(t) [a_ast1 e_ast1 inc_ast1*pi/180 Omega_ast1*pi/180 omega_ast1*pi/180 M_ast1(t)]';
x_cartesian_ast1 = @(t) keplerian_to_cartesian(x_keplerian_ast1(t),[],mu);
x_keplerian_ast2 = @(t) [a_ast2 e_ast2 inc_ast2*pi/180 Omega_ast2*pi/180 omega_ast2*pi/180 M_ast2(t)]';
x_cartesian_ast2 = @(t) keplerian_to_cartesian(x_keplerian_ast2(t),[],mu);

t_plot = linspace(0, tf, 100);
x_cartesian_ast1_plot = zeros([6, numel(t_plot)]);
x_cartesian_ast2_plot = zeros([6, numel(t_plot)]);
for k=1:numel(t_plot)
    x_cartesian_ast1_plot(:,k)=x_cartesian_ast1(t_plot(k));
    x_cartesian_ast2_plot(:,k)=x_cartesian_ast2(t_plot(k));
end

x_0 = [x_cartesian_ast1(0); m0];
x_f = [x_cartesian_ast2(tf)];

%% Finish setting up problem
tspan = [0, tf];
t_k = linspace(tspan(1), tspan(2), N);
delta_t = t_k(2) - t_k(1);

u_hold = "ZOH";
Nu = (u_hold == "ZOH") * (N - 1) + (u_hold == "FOH") * N;

parser = "CVX";

nx = 7;
nu = 3;
np = 0;

initial_guess = "straight line"; % "CasADi" or "straight line"

% PTR algorithm parameters
ptr_ops.iter_max = 50;
ptr_ops.iter_min = 2;
ptr_ops.Delta_min = 1e-5;
ptr_ops.w_vc = 1e3;
ptr_ops.w_tr = ones(1, Nu) * 5e-2;
ptr_ops.w_tr_p = 1e-1;
ptr_ops.update_w_tr = false;
ptr_ops.delta_tol = 2e-2;
ptr_ops.q = 2;
ptr_ops.alpha_x = 1;
ptr_ops.alpha_u = 1;
ptr_ops.alpha_p = 0;

scale = false;

%% Get Dynamics
f = @(t, x, u, p) dynamics(t, x, u);

%% Specify Constraints
% Convex state path constraints

% Convex control constraints
max_thrust_constraint = @(t, x, u, p) norm(u, 2)-u_max;
control_convex_constraints = {max_thrust_constraint};

% Combine convex constraints
convex_constraints = control_convex_constraints;

% Terminal boundary conditions
terminal_bc = @(x, u, p) [x(1:6) - x_f; 0];

%% Specify Objective
if u_hold == "ZOH"
    min_fuel_objective = @(x, u, p) sum(norms(u, 2, 1)) * delta_t;
elseif u_hold == "FOH"
    min_fuel_objective = @(x, u, p) sum((u(3, 1:(end - 1)) + u(3, 2:end)) / 2) * delta_t;
end

%% Create Guess
AU_guess = interp1(tspan, [a_ast1, a_ast2]', t_k);
nu_guess = interp1(tspan, [nu_ast1(0), nu_ast2(tf)]', t_k);
r_guess = [AU_guess.*cos(nu_guess); AU_guess.*sin(nu_guess)];
r_guess(end+1, :)=0;
v_guess = v_circ(r_guess, nu_guess, mu);

function [v_guess] = v_circ(r_guess, nu_guess, mu)
    r = vecnorm(r_guess, 2, 1);
    v = sqrt(mu ./ r);
    v_guess = v .* [-sin(nu_guess); cos(nu_guess)];
end
v_guess(end+1, :)=0;

m_guess=ones(1, N);

guess.x = [r_guess; v_guess; m_guess];
guess.u = interp1(tspan, ones(3, 2)'*1e-5, t_k(1:Nu))';
guess.p = [];

%% Construct Problem Object
problem = DeterministicProblem(x_0, x_f, N, u_hold, tf, f, guess, convex_constraints, min_fuel_objective, scale = scale, terminal_bc = terminal_bc, integration_tolerance = 1e-12, discretization_method = "state", N_sub = 1);

%%
% Delta = calculate_defect(problem, guess.x, guess.u, guess.p);
% norm(Delta)

%% Test Discretization on Initial Guess
[problem, Delta_disc] = problem.discretize(guess.x, guess.u, guess.p);

x_disc = problem.disc_prop(guess.u, guess.p);

[t_cont, x_cont, u_cont] = problem.cont_prop(guess.u, guess.p);

%% Solve Problem with PTR
ptr_ops.w_tr = ones(1, Nu) * 5e-2;
ptr_sol_vc = ptr(problem, ptr_ops, parser);

%%
% ptr_ops.w_vse = 1e4;
% ptr_ops.w_tr = 5e-2;
% ptr_ops.w_prime = 1e2;
% ptr_sol_vs = ptr_virtual_state(problem, ptr_ops, "CVX");

%%
ptr_sol = ptr_sol_vc;
x = ptr_sol.x(:, :, ptr_sol.converged_i + 1);
u = ptr_sol.u(:, :, ptr_sol.converged_i + 1);
r = x(1:3, :); v= x(4:6, :);

%%
i = ptr_sol.converged_i + 1;
[t_cont_sol, x_cont_sol, u_cont_sol] = problem.cont_prop(ptr_sol.u(:, :, i), ptr_sol.p(:, i));
r_cont_sol = x_cont_sol(1:3, :); v_cont_sol = x_cont_sol(4:6, :);

figure
plot_cartesian_orbit(r_cont_sol(1:3,:)', 'k', 0.4, 1); hold on
quiver3(r(1, 1:Nu), r(2, 1:Nu), r(3, 1:Nu), u(1, :), u(2, :), u(3, :), 1, "filled", Color = "red")
plot_cartesian_orbit(r_guess(1:3,:)', 'g', 0.4, 1); hold on
plot_cartesian_orbit(x_cartesian_ast1_plot(1:3, :)', 'b', 0.3, 1)
plot_cartesian_orbit(x_cartesian_ast2_plot(1:3, :)', 'cyan', 0.3, 1)
scatter3(x_cartesian_ast1_plot(1, 1), x_cartesian_ast1_plot(2, 1), x_cartesian_ast1_plot(3, 1), "green")
scatter3(x_cartesian_ast2_plot(1, end), x_cartesian_ast2_plot(2, end), x_cartesian_ast2_plot(3, end), "red")
title('Optimal Transfer Trajectory')
xlabel('x (AU)'); ylabel('y (AU)')
legend('Spacecraft', "", "Thrust", 'Guess', "", 'Asteroid 1', "", 'Asteroid 2', "", "Start", "End", 'Location', 'northwest'); axis equal; grid on

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
