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
u_max = 1;
mu = 1;
AU = 149597898;
m0 = 1;

% Problem Parameters
tf = 10; % [s]
N = 30; % []

%% Earth data
a_earth = 1.49579e8/AU;
e_earth = 1.65519e-2;
inc_earth = 4.64389e-3;
Omega_earth = 1.98956e2;
omega_earth = 2.62960e2;
M_earth0 = deg2rad(3.58040e2);
M_earth = @(t) sqrt(mu/a_earth^3)*t+M_earth0;
E_earth = @(t) mean_to_eccentric_anomaly(M_earth(t), e_earth);
nu_earth = @(t) rad2deg(eccentric_to_true_anomaly(E_earth(t), e_earth));

%% Asteroid data
a_ast = 3.073;
e_ast = 1.177e-1;
inc_ast = 17.45;
Omega_ast = 14.03;
omega_ast = 1.830;
M_ast0 = deg2rad(305.3);
M_ast = @(t) sqrt(mu/a_ast^3)*t+M_ast0;
E_ast = @(t) mean_to_eccentric_anomaly(M_ast(t), e_ast);
nu_ast = @(t) rad2deg(eccentric_to_true_anomaly(E_ast(t), e_ast));

%% Create initial conditions
x_keplerian_earth = @(t) [a_earth e_earth inc_earth*pi/180 Omega_earth*pi/180 omega_earth*pi/180 M_earth(t)]';
x_cartesian_earth = @(t) keplerian_to_cartesian(x_keplerian_earth(t),[],mu);
x_keplerian_ast = @(t) [a_ast e_ast inc_ast*pi/180 Omega_ast*pi/180 omega_ast*pi/180 M_ast(t)]';
x_cartesian_ast = @(t) keplerian_to_cartesian(x_keplerian_ast(t),[],mu);

for k=1:30
    x_cartesian_earth_plot(:,k)=x_cartesian_earth(t_k(k));
end
for k=1:30
    x_cartesian_ast_plot(:,k)=x_cartesian_ast(t_k(k));
end

x_0 = [x_cartesian_earth(0); m0];
x_f = [x_cartesian_ast(tf)];

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
ptr_ops.Delta_min = 1e-3;
ptr_ops.w_vc = 1e1;
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
AU_guess = interp1(tspan, [a_earth, a_ast]', t_k);
nu_guess = interp1(tspan, [nu_earth(0), nu_ast(tf)]', t_k);
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
figure
plot3(r(1,:), r(2,:), r(3,:), 'k'); hold on
plot_cartesian_orbit(x_cartesian_earth_plot(1:3, :)', 'b', 0.1, 1)
plot_cartesian_orbit(x_cartesian_ast_plot(1:3, :)', 'r', 0.1, 1)
title('Optimal Transfer Trajectory')
xlabel('x (AU)'); ylabel('y (AU)')
legend('Spacecraft', 'Earth', 'Mars', 'Location', 'northwest'); axis equal; grid on

figure
plot(t_k(1:Nu), u(1,:)); hold on
plot(t_k(1:Nu), u(2,:));
plot(t_k(1:Nu), u(3,:));

i = ptr_sol.converged_i + 1;
[t_cont_sol, x_cont_sol, u_cont_sol] = problem.cont_prop(ptr_sol.u(:, :, i), ptr_sol.p(:, i));
r_cont_sol = x_cont_sol(1:3, :); v_cont_sol = x_cont_sol(4:6, :);

figure
plot3(r_cont_sol(1,:), r_cont_sol(2,:), r_cont_sol(3,:), 'k'); hold on
plot(r_Earth(1,:), r_Earth(2,:), 'b')
plot(r_ast(1,:), r_ast(2,:), 'r')
title('Optimal Transfer Trajectory')
xlabel('x (AU)'); ylabel('y (AU)')
legend('Spacecraft', 'Earth', 'Mars', 'Location', 'northwest'); axis equal; grid on

figure
plot(t_cont_sol(1:end-1), u_cont_sol(1,:)); hold on
plot(t_cont_sol(1:end-1), u_cont_sol(2,:));
plot(t_cont_sol(1:end-1), u_cont_sol(3,:));