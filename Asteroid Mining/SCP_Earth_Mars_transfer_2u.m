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

AU = 149597898;

% All times are nondimensionalized by Earth's mean motion
tf = 8; % [] arrival time (nondimensionalized)

mu = 1; % [] Sun's gravitaional parameter (nondimensionalized)

% Problem Parameters
N = 30; % []

%% Earth data
a_Earth = 1.49579e8/AU;
e_Earth = 1.65519e-2;
inc_Earth = 4.64389e-3;
Omega_Earth = 1.98956e2;
omega_Earth = 2.62960e2;
M_Earth0 = deg2rad(3.58040e2);
M_Earth = @(t) sqrt(mu/a_Earth^3)*t+M_Earth0;
E_Earth = @(t) mean_to_eccentric_anomaly(M_Earth(t), e_Earth);
nu_Earth = @(t) rad2deg(eccentric_to_true_anomaly(E_Earth(t), e_Earth));

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
x_keplerian_Earth = @(t) [a_Earth e_Earth inc_Earth*pi/180 Omega_Earth*pi/180 omega_Earth*pi/180 M_Earth(t)]';
x_cartesian_Earth = @(t) keplerian_to_cartesian(x_keplerian_Earth(t),[],mu);
x_keplerian_ast = @(t) [a_ast e_ast inc_ast*pi/180 Omega_ast*pi/180 omega_ast*pi/180 M_ast(t)]';
x_cartesian_ast = @(t) keplerian_to_cartesian(x_keplerian_ast(t),[],mu);

x_0 = [x_cartesian_Earth(0); m_0];
x_f = [x_cartesian_ast(tf)];

%% Finish setting up problem

tspan = [0, tf];
t_k = linspace(tspan(1), tspan(2), N);
delta_t = tf / (N - 1);

u_hold = "ZOH";
Nu = (u_hold == "ZOH") * (N - 1) + (u_hold == "FOH") * N;

nx = 7;
nu = 3;
np = 0;

initial_guess = "straight line"; % "CasADi" or "straight line"

% PTR algorithm parameters
ptr_ops.iter_max = 30;
ptr_ops.iter_min = 2;
ptr_ops.Delta_min = 1e-3;
ptr_ops.w_vc = 1e1;
ptr_ops.w_tr = ones(1, Nu) * 5e-3;
ptr_ops.w_tr_p = 1e-1;
ptr_ops.update_w_tr = false;
ptr_ops.delta_tol = 2e-2;
ptr_ops.q = 2;
ptr_ops.alpha_x = 1;
ptr_ops.alpha_u = 1;
ptr_ops.alpha_p = 0;

scale = false;

%% Get Dynamics
f = @(t, x, u, p) state_equation(x, u, mu, alpha);

%% Specify Constraints
% Convex state path constraints
state_convex_constraints = {};

% Convex control constraints
max_control_constraint = @(t, x, u, p)  norm(u(1:2)) - u_max;
control_convex_constraints = {max_control_constraint};

% Combine convex constraints
convex_constraints = [state_convex_constraints, control_convex_constraints];

% Nonconvex state path constraints
state_nonconvex_constraints = {};

% Nonconvex control constraints
control_nonconvex_constraints = {};

nonconvex_constraints = [state_nonconvex_constraints, control_nonconvex_constraints];


% Terminal boundary conditions
terminal_bc = @(x, u, p) [x(1:4) - x_f; 0];

%% Specify Objective
min_fuel_objective = @(x, u, p) sum(norms(u(1:2, :), 2, 1)) * tf / (N - 1);

%% Create Guess
AU_guess = interp1(tspan, [a_earth, a_ast]', t_k)';
nu_guess = interp1(tspan, [nu_earth(0), nu_ast(tf)]', t_k)';
r_guess = [AU_guess .* cos(nu_guess), AU_guess .* sin(nu_guess)]';
v_guess = v_circ(r_guess, nu_guess', mu);
m_guess = m_0 * ones([1, N]);

guess.x = [r_guess; v_guess; m_guess];
guess.u = interp1(tspan, zeros(nu, 2)', t_k(1:Nu))' + 1e-3;
guess.p = [];

%% Construct Problem Object
prob = DeterministicProblem(x_0, x_f, N, u_hold, tf, f, guess, convex_constraints, min_fuel_objective, scale = scale, terminal_bc = terminal_bc, nonconvex_constraints = nonconvex_constraints);

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

%%

i = ptr_sol.converged_i + 1;
[t_cont_sol, x_cont_sol, u_cont_sol] = prob.cont_prop(ptr_sol.u(:, :, i), ptr_sol.p(:, i));

earth_trajectory = earth_pos(t_cont_sol');
mars_trajectory = mars_pos(t_cont_sol');

figure
plot(x_cont_sol(1, :), x_cont_sol(2, :), DisplayName="Minimum Fuel Transfer"); hold on
quiver(x(1, 1:Nu)',x(2, 1:Nu)',u(1, :)',u(2, :)', 1, DisplayName="Thrust"); hold on
plot(earth_trajectory(1, :), earth_trajectory(2, :), DisplayName="Earth Orbit"); hold on;
plot(mars_trajectory(1, :), mars_trajectory(2, :), DisplayName="Mars Orbit"); hold on
scatter(x_0(1), x_0(2), DisplayName="Earth at t = 0"); hold on
scatter(x_f(1), x_f(2), DisplayName=sprintf("Mars at t = %.4g", tf)); hold off;
title("Minimum Fuel Transfer Between Earth and Mars")
subtitle(sprintf("For final time of %.4g", tf))
xlabel("X [AU]")
ylabel("Y [AU]")
legend(Location="eastoutside")
grid on
axis equal

%% Plot optimal Control
fuel = sum(squeeze(vecnorm(u(1:2, 1:end))) .* tf / (N - 1), 2);

figure
tiledlayout(1, 1, "TileSpacing","compact")

nexttile
if u_hold == "ZOH"
    stairs(t_k(1:Nu), u');
elseif u_hold == "FOH"
    plot(t_k(1:Nu), u);
end
title("Optimal Control History", Interpreter="latex")
subtitle(sprintf("Total Fuel Used of %.3f units", fuel(end)))
xlabel("Time []")
ylabel("Control Value")
xlim([0, tf])
legend("u_1", "u_2", location = "south", Orientation="horizontal")
grid on

%%
N_anim = 1 / 0.01;
t_cont = linspace(0, tf, N_anim);
x_cont = interp1(t_cont_sol, x_cont_sol', t_cont)';

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

    title(sprintf('Earth-Mars Min Fuel Fixed tf Transfer\nTime: %0.0f sec | Mass: %0.2f', t(j),x_cont(5, j)),'Interpreter','Latex','Color','k');
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
    r = vecnorm(rvec, 2, 1);
    v = sqrt(mu ./ r);
    vvec = v .* [-sin(nu); cos(nu)];
end

function [pos] = keplerian2cartesian(a, e, inc, Omega, omega, nu)
    r = a*(1-e^2)/(1+e*cosd(nu));
    x=r*((cosd(Omega)*cosd(omega)-sind(Omega)*sind(omega)*cosd(inc))*cosd(nu)+(-cosd(Omega)*sind(omega)-sind(Omega)*cosd(omega)*cosd(inc))*sind(nu));
    y=r*((sind(Omega)*cosd(omega)+cosd(Omega)*sind(omega)*cosd(inc))*cosd(nu)+(-sind(Omega)*sind(omega)+cosd(Omega)*cosd(omega)*cosd(inc))*sind(nu));
    z=r*(sind(omega)*sind(inc)*cosd(nu)+cosd(omega)*sind(inc)*sind(nu));
    pos = [x; y; z];
end