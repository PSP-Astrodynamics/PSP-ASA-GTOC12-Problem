%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% AAE 590ACA
% Stochastic SCP Rocket Landing Project
% Author: Travis Hastreiter 
% Created On: 6 April, 2025
% Description: 3DoF landing of rocket using PTR SCP algorithm
% Most Recent Change: 6 April, 2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Initialize
% Vehicle Parameters
u_max = 0.1; % []
alpha = 1; % [?]
 
a_earth = 1; % [AU]
nu0_earth = 0; % [rad]

a_mars = 1.524; % [AU]
nu0_mars = pi; % [rad]

m_0 = 1;

% All times are nondimensionalized by Earth's mean motion
tf = 6; % [] arrival time (nondimensionalized)

mu = 1; % [] Sun's gravitaional parameter (nondimensionalized)

% Problem Parameters
N = 30; % []

%% Create initial conditions
P_earth_over_P_mars = (a_earth / a_mars) ^ (3/2);

earth_pos = @(t) a_earth .* [cos(t + nu0_earth); ...
                             sin(t + nu0_earth)];
mars_pos = @(t) a_mars .* [cos(t * P_earth_over_P_mars + nu0_mars); ...
                           sin(t * P_earth_over_P_mars + nu0_mars)];

nuf_mars = @(tf) tf * P_earth_over_P_mars + nu0_mars;

x_0 = [earth_pos(0); v_circ(earth_pos(0), nu0_earth, mu); m_0];
x_f = @(tf) [mars_pos(tf); v_circ(mars_pos(tf), nuf_mars(tf), mu)];

%% Finish setting up problem

tspan = [0, 1];
t_k = linspace(tspan(1), tspan(2), N);
delta_t = tf / (N - 1);

u_hold = "ZOH";
Nu = (u_hold == "ZOH") * (N - 1) + (u_hold == "FOH") * N;

nx = 5;
nu = 2;
np = 1;

% PTR algorithm parameters
ptr_ops.iter_max = 50;
ptr_ops.iter_min = 2;
ptr_ops.Delta_min = 1e-3;
ptr_ops.w_vc = 1e2;
ptr_ops.w_tr = ones(1, Nu) * 5e-3;
ptr_ops.w_tr_p = 1e-1;
ptr_ops.update_w_tr = false;
ptr_ops.delta_tol = 1e-2;
ptr_ops.q = 2;
ptr_ops.alpha_x = 1e-1;
ptr_ops.alpha_u = 1;
ptr_ops.alpha_p = 0;

scale = false;

%% Get Dynamics
f = @(t, x, u, p) state_equation(x, u, mu, alpha) * p(1);

%% Specify Constraints
% Convex state path constraints
state_convex_constraints = {};

% Convex control constraints
max_control_constraint = @(t, x, u, p) norm(u(1:2)) - u_max;
control_convex_constraints = {max_control_constraint};

% Convex parameter constraints
%min_time_constraint = @(t, x, u, p) 40 - p(1); 
parameter_convex_constraints = {};

% Combine convex constraints
convex_constraints = [state_convex_constraints, control_convex_constraints, parameter_convex_constraints];

% Nonconvex state path constraints
state_nonconvex_constraints = {};

% Nonconvex control constraints
control_nonconvex_constraints = {};

nonconvex_constraints = [state_nonconvex_constraints, control_nonconvex_constraints];


% Terminal boundary conditions
terminal_bc = @(t, x, u, p) [x(1:4) - x_f(p(1)); 0];
terminal_bc_linearized = linearize_constraint(terminal_bc, nx, nu, np, "p", 1);
terminal_bc_linearized = @(x, p, x_ref, p_ref) terminal_bc_linearized(0, x, 0, p, x_ref, 0, p_ref);

%% Specify Objective
min_fuel_objective = @(x, u, p, x_ref, u_ref, p_ref) sum(norms(u(1:2, :), 2, 1)) * p_ref(1) / (N - 1) + sum(norms(u_ref(1:2, :), 2, 1)) * (p(1) - p_ref(1)) / (N - 1);

%% Create Guess
AU_guess = interp1(tspan, [a_earth, a_mars]', t_k)';
nu_guess = interp1(tspan, [nu0_earth, nuf_mars(tf)]', t_k)';
r_guess = [AU_guess .* cos(nu_guess), AU_guess .* sin(nu_guess)]';
v_guess = v_circ_array(r_guess, nu_guess', mu);
m_guess = m_0 * ones([1, N]);

guess.x = [r_guess; v_guess; m_guess];
guess.u = interp1(tspan, zeros(nu, 2)', t_k(1:Nu))' + 1e-3;
guess.p = tf;

%% Construct Problem Object
prob = DeterministicProblem(x_0, x_f, N, u_hold, 1, f, guess, convex_constraints, min_fuel_objective, scale = scale, terminal_bc = terminal_bc_linearized, nonconvex_constraints = nonconvex_constraints);

%%
Delta = calculate_defect(prob, guess.x, guess.u, guess.p);
norm(Delta)

%% Test Discretization on Initial Guess

[prob, Delta_disc] = prob.discretize(guess.x, guess.u, guess.p);

x_disc = prob.disc_prop(guess.u, guess.p);

[t_cont, x_cont, u_cont] = prob.cont_prop(guess.u, guess.p);

%% Solve Problem with PTR
ptr_sol = ptr(prob, ptr_ops);

%%
if ~ptr_sol.converged
    ptr_sol.converged_i = ptr_ops.iter_max;
end

x = ptr_sol.x(:, :, ptr_sol.converged_i + 1);
u = ptr_sol.u(:, :, ptr_sol.converged_i + 1);
p = ptr_sol.p(:, ptr_sol.converged_i + 1);

%%

i = ptr_sol.converged_i + 1;
[t_cont_sol, x_cont_sol, u_cont_sol] = prob.cont_prop(ptr_sol.u(:, :, i), ptr_sol.p(:, i));

earth_trajectory = earth_pos(t_cont_sol' * p(1));
mars_trajectory = mars_pos(t_cont_sol' * p(1));

xf = x_f(p(1));

figure
plot(x_cont_sol(1, :), x_cont_sol(2, :), DisplayName="Minimum Fuel Transfer"); hold on
quiver(x(1, 1:Nu)',x(2, 1:Nu)',u(1, :)',u(2, :)', 1, DisplayName="Thrust"); hold on
plot(earth_trajectory(1, :), earth_trajectory(2, :), DisplayName="Earth Orbit"); hold on;
plot(mars_trajectory(1, :), mars_trajectory(2, :), DisplayName="Mars Orbit"); hold on
scatter(x_0(1), x_0(2), DisplayName="Earth at t = 0"); hold on
scatter(xf(1), xf(2), DisplayName=sprintf("Mars at t = %.4g", p(1))); hold off;
title("Minimum Fuel Transfer Between Earth and Mars")
subtitle(sprintf("For final time of %.4g", p(1)))
xlabel("X [AU]")
ylabel("Y [AU]")
legend(Location="eastoutside")
grid on
axis equal

%% Plot optimal Control
fuel = sum(squeeze(vecnorm(u(1:2, 1:end))) .* p(1) / (N - 1), 2);

figure
tiledlayout(1, 1, "TileSpacing","compact")

nexttile
if u_hold == "ZOH"
    stairs(t_k(1:Nu) * p(1), u');
elseif u_hold == "FOH"
    plot(t_k(1:Nu) * p(1), u);
end
title("Optimal Control History", Interpreter="latex")
subtitle(sprintf("Total Fuel Used of %.3f units", fuel(end)))
xlabel("Time []")
ylabel("Control Value")
xlim([0, p(1)])
legend("u_1", "u_2", location = "south", Orientation="horizontal")
grid on

%%
N_anim = 1 / 0.01;
t_cont = linspace(0, p(1), N_anim);
x_cont = interp1(t_cont_sol * p(1), x_cont_sol', t_cont)';

earth_trajectory = earth_pos(t_cont);
mars_trajectory = mars_pos(t_cont);

figure
t = t_cont;

r1 = x_cont(1,:)';
r2 = x_cont(2,:)';
r3 = x_cont(1,:)' * 0;

r = sqrt(r1.^2 + r2.^2 + r3.^2);

spacecraft = animatedline('LineWidth',2);
mars = animatedline('lineWidth', 1);

hold on;

spacecraft.Color = 'blue';
spacecraft.Visible = 'on';
mars.Color = 'red';
mars.Visible = 'on';

title(sprintf('Spacecraft 1\nTime: %0.2f sec | Radius: %0.2f', t(1),r(1)), 'Interpreter', 'latex','Color','k');

j_0 = int16((t(1) / t(length(t)))*(length(t))) + 1; % stating time index (integer)

for j = j_0:length(t) % this foor loop generates the animated plot with position vectors with indexes
    addpoints(spacecraft,r1(j),r2(j),r3(j));
    addpoints(mars,mars_trajectory(1, j), mars_trajectory(2, j), 0);
    head = scatter3(r1(j),r2(j),r3(j),'filled','MarkerFaceColor','b','LineWidth', 0.8);
    mars_head = scatter3(mars_trajectory(1, j), mars_trajectory(2, j), 0, "red", "filled");

    drawnow
    pause(0.01);
    delete(head);
    delete(mars_head);

    title(sprintf('Earth-Mars Min Fuel Transfer\nTime: %0.0f sec | Mass: %0.2f', t(j),x_cont(5, j)),'Interpreter','Latex','Color','k');
    axis equal
    grid on
end

%% Helper Functions
function [xdot] = state_equation(x, u, mu, alpha)
    rvec = x(1:2);
    vvec = x(3:4);
    m = x(5);
    r = sqrt(rvec(1) ^ 2 + rvec(2) ^ 2);
    
    f0 = [vvec; -mu / r ^ 3 * rvec];

    B = [zeros(2); eye(2)];

    u_mag = sqrt(u(1) ^ 2 + u(2) ^ 2);

    m_dot = -alpha * u_mag;

    xdot = [f0 + B * u(1:2) / m; m_dot];
end

function [vvec] = v_circ(rvec, nu, mu)
    r = norm(rvec);
    v = sqrt(mu / r);
    vvec = v .* [-sin(nu); cos(nu)];
end

function [vvec] = v_circ_array(rvec, nu, mu)
    r = vecnorm(rvec, 2, 1);
    v = sqrt(mu ./ r);
    vvec = v .* [-sin(nu); cos(nu)];
end