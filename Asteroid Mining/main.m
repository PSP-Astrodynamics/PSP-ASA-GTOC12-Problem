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
a_Earth = 1; a_Mars = 1.524;
theta0_Earth = 0; theta0_Mars = pi;
omega_Earth = sqrt(mu / a_Earth^3);
omega_Mars = sqrt(mu / a_Mars^3);

% Problem Parameters
tf = 8; % [s]
N = 100; % []
r_0 = [a_Earth; 0];
v_0 = [0; sqrt(mu/a_Earth)];
r_f = [a_Mars*cos(omega_Mars*tf+theta0_Mars); a_Mars*sin(omega_Mars*tf+theta0_Mars)];
v_f = omega_Mars*a_Mars*[-sin(omega_Mars*tf+theta0_Mars); cos(omega_Mars*tf+theta0_Mars)];
thetaf_Mars = acos(r_f(1)/r_f(2))+2*pi;

x_0 = [r_0; v_0];
x_f = [r_f; v_f];

tspan = [0, tf];
t_k = linspace(tspan(1), tspan(2), N);
delta_t = t_k(2) - t_k(1);

u_hold = "ZOH";
Nu = (u_hold == "ZOH") * (N - 1) + (u_hold == "FOH") * N;

parser = "CVX";

% PTR algorithm parameters
ptr_ops.iter_max = 20;
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
f = @(t, x, u, p) dynamics_asteroidmining(t, x, u);

%% Specify Constraints
% Convex state path constraints

% Convex control constraints
max_thrust_constraint = @(t, x, u, p) norm(u, 2)-u_max;
control_convex_constraints = {max_thrust_constraint};

% Combine convex constraints
convex_constraints = control_convex_constraints;

% Terminal boundary conditions
terminal_bc = @(x, u, p) x - x_f;

%% Specify Objective
if u_hold == "ZOH"
    min_fuel_objective = @(x, u, p) sum(norms(u, 2, 1)) * delta_t;
elseif u_hold == "FOH"
    min_fuel_objective = @(x, u, p) sum((u(3, 1:(end - 1)) + u(3, 2:end)) / 2) * delta_t;
end

%% Create Guess
AU_guess = interp1(tspan, [a_Earth, a_Mars]', t_k);
theta_guess = interp1(tspan, [theta0_Earth, thetaf_Mars]', t_k);
r_guess = [AU_guess.*cos(theta_guess); AU_guess.*sin(theta_guess)];
v_guess = v_circ(r_guess, theta_guess, mu);

function [v_guess] = v_circ(r_guess, theta_guess, mu)
    r = vecnorm(r_guess, 2, 1);
    v = sqrt(mu ./ r);
    v_guess = v .* [-sin(theta_guess); cos(theta_guess)];
end

guess.x = [r_guess; v_guess];
guess.u = interp1(tspan, zeros(2, 2)', t_k(1:Nu))';
guess.p = [];

%% Construct Problem Object
problem = DeterministicProblem(x_0, x_f, N, u_hold, tf, f, guess, convex_constraints, min_fuel_objective, scale = scale, terminal_bc = terminal_bc, integration_tolerance = 1e-12, discretization_method = "state", N_sub = 1);

%%
Delta = calculate_defect(problem, guess.x, guess.u, guess.p);
norm(Delta)

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
r = x(1:2, :); v= x(3:4, :);

r_Earth = [a_Earth*cos(omega_Earth*t_k+theta0_Earth); a_Earth*sin(omega_Earth*t_k+theta0_Earth)];
r_Mars  = [a_Mars*cos(omega_Mars*t_k+theta0_Mars); a_Mars*sin(omega_Mars*t_k+theta0_Mars)];
v_Earth = omega_Earth*a_Earth*[-sin(omega_Earth*t_k+theta0_Earth); cos(omega_Earth*t_k+theta0_Earth)];
v_Mars = omega_Mars*a_Mars*[-sin(omega_Mars*t_k+theta0_Mars); cos(omega_Mars*t_k+theta0_Mars)];

figure
plot(r(1,:), r(2,:), 'k'); hold on
plot(r_Earth(1,:), r_Earth(2,:), 'b')
plot(r_Mars(1,:), r_Mars(2,:), 'r')
title('Optimal Transfer Trajectory')
xlabel('x (AU)'); ylabel('y (AU)')
legend('Spacecraft', 'Earth', 'Mars', 'Location', 'northwest'); axis equal; grid on

figure
plot(t_k(1:Nu), u(1,:)); hold on
plot(t_k(1:Nu), u(2,:));

i = ptr_sol.converged_i + 1;
[t_cont_sol, x_cont_sol, u_cont_sol] = problem.cont_prop(ptr_sol.u(:, :, i), ptr_sol.p(:, i));
r_cont_sol = x_cont_sol(1:2, :); v_cont_sol = x_cont_sol(3:4, :);

figure
plot(r_cont_sol(1,:), r_cont_sol(2,:), 'k'); hold on
plot(r_Earth(1,:), r_Earth(2,:), 'b')
plot(r_Mars(1,:), r_Mars(2,:), 'r')
title('Optimal Transfer Trajectory')
xlabel('x (AU)'); ylabel('y (AU)')
legend('Spacecraft', 'Earth', 'Mars', 'Location', 'northwest'); axis equal; grid on

figure
plot(t_cont_sol(1:end-1), u_cont_sol(1,:)); hold on
plot(t_cont_sol(1:end-1), u_cont_sol(2,:));