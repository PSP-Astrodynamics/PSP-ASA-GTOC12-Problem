%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% AAE 590ACA
% Stochastic SCP Rocket Landing Project
% Author: Travis Hastreiter 
% Created On: 6 April, 2025
% Description: 3DoF landing of rocket using PTR SCP algorithm
% Most Recent Change: 30 June, 2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Initialize
% Vehicle Parameters
alpha = 0.5086; % [s / km]
m_dry = 1100; % [kg]
m_wet = 1000; % [kg]
m_0 = m_dry + m_wet;
T_max = 3 * m_0 * 9.81e-3; % [kg km / s2]
T_min = 0.55 * T_max; % [kg km / s2]
I = 150000 * (1e-3) ^ 2; % [kg km2] ASSUMING CONSTANT MOMENT OF INERTIA
L = 3e-3; % [km] Distance from CoM to nozzle
gimbal_max = deg2rad(6); % [rad]
 
vehicle = Vehicle(m_dry, L, L * 3, gimbal_max, T_min, T_max, I = I, alpha = alpha);
%vehicle_big_gimbs = Vehicle(m_dry, L, L * 3, deg2rad(20), T_min, T_max, I = I, alpha = alpha);

% Problem Parameters
tf = 35; % [s]
N = 25; % []
r_0 = [0; 4.6]; % [km]
theta_0 = deg2rad(120); % [rad]
v_0 = make_R2(deg2rad(-60)) * [0.306; 0]; % [km / s]
w_0 = deg2rad(0); % [rad / s]
glideslope_angle_max = deg2rad(70); % [rad]

x_0 = [r_0; v_0; theta_0; w_0; log(m_0)];
x_f = [zeros(2, 1); zeros(2, 1); pi / 2; 0];

%%
v_0_b = make_R2(theta_0)' * v_0 - eye(2, 3) * cross([0; 0; w_0], [r_0; 0]);
incidence_0 = atan2(v_0_b(2), v_0_b(1));

%%

tspan = [0, tf];
t_k = linspace(tspan(1), tspan(2), N);
delta_t = t_k(2) - t_k(1);

u_hold = "FOH";
Nu = (u_hold == "ZOH") * (N - 1) + (u_hold == "FOH") * N;

initial_guess = "straight line"; % "CasADi" or "straight line" or "screw"
parser = "CVX";

% PTR algorithm parameters
ptr_ops.iter_max = 20;
ptr_ops.iter_min = 2;
ptr_ops.Delta_min = 1e-2;
ptr_ops.w_vc = 1e4;
ptr_ops.w_tr = ones(1, Nu) * 5e-2;
ptr_ops.w_tr_p = 1e-1;
ptr_ops.update_w_tr = false;
ptr_ops.delta_tol = 2e-2;
ptr_ops.q = 2;
ptr_ops.alpha_x = 1;
ptr_ops.alpha_u = 1;
ptr_ops.alpha_p = 0;

scale = true;

%% Get Dynamics
f = @(t, x, u, p) SymDynamics3DoF_mass_convexified(t, x, u, vehicle.L, vehicle.I(2), vehicle.alpha);

%% Specify Constraints
% Convex state path constraints
glideslope_constraint = {1:N, @(t, x, u, p) norm(x(1:2)) - x(2) / cos(glideslope_angle_max)};
state_convex_constraints = {glideslope_constraint};

z_lb = @(t) log(m_0 - alpha * T_max * t);
z_lb_k = z_lb(t_k);

% Convex control constraints
max_thrust_constraint = {1:N, @(t, x, u, p) u(3) - T_max * exp(-z_lb(t)) * (1 - (x(7) - z_lb(t)))};
min_thrust_constraint = {1:N, @(t, x, u, p) T_min * exp(-z_lb(t)) * (1 - (x(7) - z_lb(t)) + 0.5 * (x(7) - z_lb(t)) ^ 2) - u(3)};
max_gimbal_constraint = {1:N, @(t, x, u, p) u(3) - u(1) / cos(gimbal_max)};
lcvx_thrust_constraint = {1:N, @(t, x, u, p) norm(u(1:2)) - u(3)}; 
control_convex_constraints = {min_thrust_constraint,max_gimbal_constraint,max_thrust_constraint,lcvx_thrust_constraint};

% Combine convex constraints
convex_constraints = [state_convex_constraints, control_convex_constraints];

% Nonconvex state constraints
glideslope_STC_angle = deg2rad(5);
glideslope_STC_trigger_height = 0.5; % [km]
glideslope_STC_constraint = {1:N, @(t, x, u, p, x_ref, u_ref, p_ref, k) (norm(x(1:2)) - x(2) / cos(glideslope_STC_angle)) * (x_ref(2, k) <= glideslope_STC_trigger_height)};
state_nonconvex_constraints = {glideslope_STC_constraint};

nonconvex_constraints = [state_nonconvex_constraints];

% Terminal boundary conditions
terminal_bc = @(x, u, p) [x(1:6, :) - x_f; 0];

%% Specify Objective
min_fuel_angular_velocity_objective = @(x, u, p) sum(u(3, :) / T_max + x(6, 1:Nu) .^ 2) * delta_t;
if u_hold == "ZOH"
    min_fuel_objective = @(x, u, p) sum(u(3, :)) * delta_t;
elseif u_hold == "FOH"
    min_fuel_objective = @(x, u, p) sum((u(3, 1:(end - 1)) + u(3, 2:end)) / 2) * delta_t;
end

%% Create Guess
sl_guess = guess_3DoF(x_0(1:6), x_f + [0; 0; 0; 0; 0; 0], N, Nu, delta_t, vehicle);
if u_hold == "ZOH"
    sl_guess.x = [sl_guess.x; m_0 - alpha * [0, cumsum(sl_guess.u(3, 1:(end - 1)) * delta_t), sum(sl_guess.u(3, 1:(end - 1))) * delta_t]];
elseif u_hold == "FOH"
    sl_guess.x = [sl_guess.x; m_0 - alpha * [0, cumsum(sl_guess.u(3, 1:(end - 1)) * delta_t)]];
end
sl_guess.x(7, :) = log(sl_guess.x(7, :));
sl_guess.u = sl_guess.u .* exp(-sl_guess.x(7, 1:Nu));

% 
% R_A = make_R(x_0(5), 1);
% 
% R_A_UQ = rot2quat(R_A);
% p_A_Q = [0 0 x_0(1:2)'];
% A_UDQ = [R_A_UQ, 1/2*quatProduct(p_A_Q , R_A_UQ)];
% 
% R_B = make_R(x_f(5), 1);
% 
% R_B_UQ = rot2quat(R_B);
% p_B_Q = [0 0 x_f(1:2)'];
% B_UDQ = [R_B_UQ, 1/2*quatProduct(p_B_Q , R_B_UQ)];
% 
% [R, p] = sclerp(A_UDQ, B_UDQ, N);
% 
% [~, ~, y] = dcm2angle(R);
% 
% scl_guess = struct();
% scl_guess.x = [p(:, 2:3)'; [diff(p(:, 2:3))', zeros([2, 1])]; y'; [diff(y)', 0]];
% scl_guess.x([1, 3], :) = -scl_guess.x([1, 3], :);
% scl_guess.u = sl_guess.u;
% scl_guess.p = sl_guess.p;
% 
% if u_hold == "ZOH"
%     scl_guess.x = [scl_guess.x; m_0 - alpha * [0, cumsum(scl_guess.u(3, 1:(end - 1)) * delta_t), sum(scl_guess.u(3, 1:(end - 1))) * delta_t]];
% elseif u_hold == "FOH"
%     scl_guess.x = [scl_guess.x; m_0 - alpha * [0, cumsum(scl_guess.u(3, 1:(end - 1)) * delta_t)]];
% end
% scl_guess.x(7, :) = log(scl_guess.x(7, :));

CasADi_sol = CasADi_solve_mass_convexified(x_0, sl_guess.x, sl_guess.u, vehicle, N, delta_t, glideslope_angle_max);%

if initial_guess == "straight line"
    guess = sl_guess;
elseif initial_guess == "screw"
    guess = scl_guess;
elseif initial_guess == "CasADi"
    guess = CasADi_sol;
end
if u_hold == "ZOH"
    guess.u = interp1(t_k(1:size(guess.u, 2)), guess.u', t_k(1:Nu), "previous","extrap")';
elseif u_hold == "FOH"
    guess.u = interp1(t_k(1:size(guess.u, 2)), guess.u', t_k(1:Nu), "linear","extrap")';
end
guess.p = sl_guess.p;

figure
plot_3DoFc_trajectory(t_k, sl_guess.x, sl_guess.u, glideslope_angle_max, gimbal_max, T_min, T_max)

figure
plot_3DoFc_time_histories(t_k, sl_guess.x, sl_guess.u)

figure
plot_3DoFc_trajectory(t_k, guess.x, guess.u, glideslope_angle_max, gimbal_max, T_min, T_max, step = 1)

figure
plot_3DoFc_time_histories(t_k, guess.x, guess.u)

%% Construct Problem Object
prob_3DoF = DeterministicProblem(x_0, x_f, N, u_hold, tf, f, guess, convex_constraints, min_fuel_objective, scale = scale, terminal_bc = terminal_bc, nonconvex_constraints = nonconvex_constraints, integration_tolerance = 1e-8, discretization_method = "error", N_sub = 1);

%% Test Scaling
% guess_scaled.x = prob_3DoF.scale_x(guess.x);
% guess_scaled.u = prob_3DoF.scale_u(guess.u);
% guess_scaled.p = prob_3DoF.scale_p(guess.p);
% 
% figure
% plot_3DoF_trajectory(t_k, guess_scaled.x, guess_scaled.u, glideslope_angle_max, gimbal_max, 0, 0)
% 
% figure
% plot_3DoF_time_histories(t_k, guess_scaled.x, guess_scaled.u)

%%
Delta = calculate_defect(prob_3DoF, guess.x, guess.u, guess.p);
norm(Delta)

%% Test Discretization on Initial Guess

[prob_3DoF, Delta_disc] = prob_3DoF.discretize(guess.x, guess.u, guess.p);

x_disc = prob_3DoF.disc_prop(guess.u, guess.p);

[t_cont, x_cont, u_cont] = prob_3DoF.cont_prop(guess.u, guess.p);

figure
comparison_plot_3DoF_trajectory({guess.x, x_cont, x_disc}, ["Guess", "Continuous Propagation", "Discrete Propagation"], glideslope_angle_max, linestyle = [":", "-", "--"], title = "Continuous vs Discrete Propagation of Initial Guess")

figure
comparison_plot_3DoFc_time_histories({t_k, t_cont, t_k}, {guess.x, x_cont, x_disc}, {guess.u, u_cont, guess.u}, ["Guess", "Cont", "Disc"], linestyle = [":", "-", "--"], title = "Continuous vs Discrete Propagation of Initial Guess")

%%
prob_3DoF = DeterministicProblem(x_0, x_f, N, u_hold, tf, f, guess, convex_constraints, min_fuel_objective, scale = scale, nonconvex_constraints = nonconvex_constraints, terminal_bc = terminal_bc, integration_tolerance = 1e-12, discretization_method = "error", N_sub = 1);
prob_3DoF.vehicle = vehicle;

[prob_3DoF, Delta_disc] = prob_3DoF.discretize(guess.x, guess.u, guess.p);

%%
prob_3DoF.params = [T_min, T_max, alpha, glideslope_angle_max, gimbal_max];

%%
%%
nx = 7;
nu = 3;
np = 0;

% Linearized matrices
t_sym = sym("t");
x_sym = sym("x", [nx, 1]);
u_sym = sym("u", [nu, 1]);
p_sym = sym("p", [np, 1]);

A = matlabFunction(jacobian(f(t_sym, x_sym, u_sym, p_sym), x_sym),"Vars", [{t_sym}; {x_sym}; {u_sym}; {p_sym}]);
B = matlabFunction(jacobian(f(t_sym, x_sym, u_sym, p_sym), u_sym),"Vars", [{t_sym}; {x_sym}; {u_sym}; {p_sym}]);
S = matlabFunction(jacobian(f(t_sym, x_sym, u_sym, p_sym), p_sym),"Vars", [{t_sym}; {x_sym}; {u_sym}; {p_sym}]);

A_k = prob_3DoF.disc.A_k;
B_k_plus = prob_3DoF.disc.B_plus_k;
B_k_minus = prob_3DoF.disc.B_minus_k;
S_k = prob_3DoF.disc.E_k;
d_k = prob_3DoF.disc.c_k;

%% Try RK4 Discretization
N_sub = 100;
[A_k_rk4, B_k_plus_rk4, B_k_minus_rk4, S_k_rk4, d_k_rk4, Delta_rk4] = discretize_error_dynamics_FOH_RK4(f, A, B, S, N, tspan, guess.x, guess.u, guess.p, N_sub);

A_err = sum(pagenorm(A_k_rk4 - A_k), "all");
B_minus_err = sum(pagenorm(B_k_minus_rk4 - B_k_minus), "all");
B_plus_err = sum(pagenorm(B_k_plus_rk4 - B_k_plus), "all");
S_err = sum(pagenorm(S_k_rk4 - S_k), "all");
d_err = sum(pagenorm(d_k_rk4 - d_k), "all");
Delta_err = norm(Delta_rk4 - Delta_disc);
fprintf("A: %.3f, B-: %.3f, B+: %.3f, S: %.3f, d: %.3f, Delta: %.5f\n", A_err, B_minus_err, B_plus_err, S_err, d_err, Delta_err);

%% Try RKV6(5) Discretization
N_sub = 1;
[A_k_rk65, B_k_plus_rk65, B_k_minus_rk65, S_k_rk65, d_k_rk65, Delta_rk65] = discretize_error_dynamics_FOH_RKV65(f, A, B, S, N, tspan, guess.x, guess.u, guess.p, N_sub);

A_err = sum(pagenorm(A_k_rk65 - A_k), "all");
B_minus_err = sum(pagenorm(B_k_minus_rk65 - B_k_minus), "all");
B_plus_err = sum(pagenorm(B_k_plus_rk65 - B_k_plus), "all");
S_err = sum(pagenorm(S_k_rk65 - S_k), "all");
d_err = sum(pagenorm(d_k_rk65 - d_k), "all");
Delta_err = norm(Delta_rk65 - Delta_disc);
fprintf("A: %.3f, B-: %.3f, B+: %.3f, S: %.3f, d: %.3f, Delta: %.10f\n", A_err, B_minus_err, B_plus_err, S_err, d_err, Delta_err);

%% Try RKV8(7) Discretization
N_sub = 1;
[A_k_rk87, B_k_plus_rk87, B_k_minus_rk87, S_k_rk87, d_k_rk87, Delta_rk87] = discretize_error_dynamics_FOH_RKV87(f, A, B, S, N, tspan, guess.x, guess.u, guess.p, N_sub);

A_err = sum(pagenorm(A_k_rk87 - A_k), "all");
B_minus_err = sum(pagenorm(B_k_minus_rk87 - B_k_minus), "all");
B_plus_err = sum(pagenorm(B_k_plus_rk87 - B_k_plus), "all");
S_err = sum(pagenorm(S_k_rk87 - S_k), "all");
d_err = sum(pagenorm(d_k_rk87 - d_k), "all");
Delta_err = norm(Delta_rk87 - Delta_disc);
fprintf("A: %.3f, B-: %.3f, B+: %.3f, S: %.3f, d: %.3f, Delta: %.10f\n", A_err, B_minus_err, B_plus_err, S_err, d_err, Delta_err);


%% Solve Problem with PTR
%ptr_ops.w_tr = ones(1, Nu) * 5e-2;
ptr_sol_vc = ptr(prob_3DoF, ptr_ops, parser);

% %%
% ptr_ops.w_vse = 1e4;
% ptr_ops.w_tr = 5e-2;
% ptr_ops.w_prime = 1e2;
% ptr_sol_vs = ptr_virtual_state(prob_3DoF, ptr_ops, "CVX");

%%
ptr_sol = ptr_sol_vc;

if ~ptr_sol.converged
    ptr_sol.converged_i = ptr_ops.iter_max;
end

%%
figure
tiledlayout(1, 3)

nexttile
plot(0:ptr_sol.converged_i, [prob_3DoF.objective(prob_3DoF.guess.x, prob_3DoF.guess.u, prob_3DoF.guess.p), [ptr_sol.info.J]]); hold on
%yline(CasADi_sol.objective); hold off
legend("PTR Iterations", "CasADi Solution")
title("Objective vs Iteration")
grid on

nexttile
plot(ptr_sol.delta_xp)
yscale("log")
title("Stopping Criteria vs Iteration")
grid on

nexttile
plot(0:ptr_sol.converged_i, vecnorm(ptr_sol.Delta(:, 1:(ptr_sol.converged_i + 1)), 2, 1))
yscale("log")
title("Defect Norm vs Iteration")
grid on

%%
Js = [ptr_sol.info.J];
(Js(end) - CasADi_sol.objective) / CasADi_sol.objective * 100

%%
figure
plot(0:ptr_sol.converged_i, [prob_3DoF.objective(prob_3DoF.guess.x, prob_3DoF.guess.u, prob_3DoF.guess.p), [ptr_sol.info.J]]); hold on
yline(CasADi_sol.objective); hold off
xlabel("PTR Iteration")
ylabel("\Delta V [km / s]")
legend("PTR Iterations", "CasADi Solution", location = "southeast")
grid on

%%
figure
plot(0:ptr_sol.converged_i, vecnorm(ptr_sol.Delta(:, 1:(ptr_sol.converged_i + 1)), 2, 1))
xlabel("PTR Iteration")
ylabel("Defect")
yscale("log")
xlim([0, ptr_sol.converged_i])
grid on

%%
i = ptr_sol.converged_i;

[t_cont_sol, x_cont_sol, u_cont_sol] = prob_3DoF.cont_prop(ptr_sol.u(:, :, i), ptr_sol.p);

plot_3DoFc_trajectory(t_cont_sol, x_cont_sol, u_cont_sol, glideslope_angle_max, gimbal_max, T_min, T_max, step = 1)

%%

figure
plot_3DoFc_trajectory(t_k, ptr_sol.x(:, :, i), ptr_sol.u(:, :, i), glideslope_angle_max, gimbal_max, T_min, T_max, step = 1)
%%
figure
comparison_plot_3DoF_trajectory({guess.x, x_cont_sol, ptr_sol.x(:, :, i), CasADi_sol.x}, ["Guess", "Continuous Propagation", "Solution Output", "CasADi"], glideslope_angle_max, linestyle = [":", "-", "--", "-"], title = "3DoF Solution Comparison")
%%
figure
comparison_plot_3DoF_trajectory({guess.x, x_cont_sol, CasADi_sol.x}, ["Guess", "PTR", "CasADi"], glideslope_angle_max, linestyle = [":", "-", "-"], title = "", STC_glideslope_angle_height = [glideslope_STC_angle, glideslope_STC_trigger_height])

%%
figure
comparison_plot_3DoFc_time_histories({t_k, t_cont_sol, t_k}, {guess.x, x_cont_sol, ptr_sol.x(:, :, i)}, {guess.u, u_cont_sol, ptr_sol.u(:, :, i)}, ["Guess", "Cont", "Disc"], linestyle = [":", "-", "--"], title = "Continuous vs Discrete Propagation of Solution")

%%
comparison_plot_3DoFc_time_histories({t_k, t_cont_sol, t_k}, {CasADi_sol.x, x_cont_sol, ptr_sol.x(:, :, i)}, {CasADi_sol.u, u_cont_sol, ptr_sol.u(:, :, i)}, ["CasADi", "Cont", "Disc"], linestyle = [":", "-", "--"], title = "Continuous vs Discrete Propagation of Solution")

%%
t_iters = {};
x_iters = {};
u_iters = {};
linestyle = string(1:ptr_sol.converged_i);
for i = 1:ptr_sol.converged_i
    t_iters{i} = t_k;
    x_iters{i} = ptr_sol.x(:, :, i);
    u_iters{i} = ptr_sol.u(:, :, i);
    linestyle(i) = "-";
end
figure
comparison_plot_3DoF_trajectory(x_iters, "iter " + string(1:ptr_sol.converged_i), glideslope_angle_max, linestyle = linestyle, title = "Solution vs Iteration")

figure 
comparison_plot_3DoFc_time_histories(t_iters, x_iters, u_iters, "iter " + string(1:ptr_sol.converged_i), linestyle = linestyle, title = "Solution vs Iteration")

%%
figure
plot(t_k(1:Nu), ptr_sol.u(3, :, i)); hold on
plot(t_k(1:Nu), vecnorm(ptr_sol.u(1:2, :, i)));
grid on

%% Validate with 3DoF Simulink Model
opt_time = t_k;
control_inputs = ptr_sol.u(:, :, i);
input_vector = 1:nu;
x_opt = ptr_sol.x(:, :, i);
state_vector = 1:nx;

T_e = zeros([2, N]);
v_B = zeros([2, N]);

for j = 1:N
    T_e(:, j) = make_R2(x_opt(5, j)) * control_inputs(1:2, j) .* exp(x_opt(7, j));
    v_B(:, j) = make_R2(x_opt(5, j))' * x_opt(3:4, j) - eye(2, 3) * cross([0; 0; x_opt(6, j)], [x_opt(1:2, j); 0]);
end

%% Validate with 6DoF Simulink Model
opt_time = t_k;
control_inputs = ptr_sol.u(:, :, i);
input_vector = 1:nu;
x_opt = ptr_sol.x(:, :, i);
state_vector = 1:nx;
r_0_6DoF = [r_0(1); 0; r_0(2)];
v_0_6DoF = [v_0(1); 0; v_0(2)];
v_0_b_6DoF = [v_0_b(1); 0; v_0_b(2)];
rpy_0_6DoF = [0; theta_0; 0];
w_0_6DoF = [0; w_0; 0];

x_0_6DoF = [r_0_6DoF; v_0_6DoF; rpy_0_6DoF; w_0_6DoF; log(m_0)];
I_matrix = diag([I/5, I, I]);

T_e = zeros([2, N]);
v_B = zeros([2, N]);

for j = 1:N
    T_e(:, j) = make_R2(x_opt(5, j)) * control_inputs(1:2, j) .* exp(x_opt(7, j));
    v_B(:, j) = make_R2(x_opt(5, j))' * x_opt(3:4, j) - eye(2, 3) * cross([0; 0; x_opt(6, j)], [x_opt(1:2, j); 0]);
end

%% Helper Functions
function Q = rot2quat(R)
q_0 = 1/2*sqrt(trace(R)+1);
q_r = 1/2*[...
    sign(R(3,2) - R(2,3))*sqrt(R(1,1) - R(2,2) - R(3,3) + 1)
    sign(R(1,3) - R(3,1))*sqrt(R(2,2) - R(3,3) - R(1,1) + 1)
    sign(R(2,1) - R(1,2))*sqrt(R(3,3) - R(1,1) - R(2,2) + 1)];
Q = [q_0 q_r.'];
end

function PQ = quatProduct(P, Q)
p_0 = P(1);
q_0 = Q(1);
p_r = P(2:4);
q_r = Q(2:4);
scalarPart = p_0*q_0 - dot(p_r,q_r);
vectorPart = p_0*q_r + q_0*p_r + cross(p_r,q_r);
PQ = [scalarPart vectorPart];
end