addpath(genpath(pwd));

%% Initialize
AU = 1.49579151285e8;
mu_star = 1.32712440018e11; % [km3 / s2]
l_star = AU; % [km] one AU
m_star = 3000; % [kg] - max initial ship mass
a_star = mu_star / l_star ^ 2; % [km / s2]
t_star = sqrt(l_star ^ 3 / mu_star);
v_star = sqrt(mu_star/l_star);

year_to_sec = 86400.0 * 365.25;

u_max = 0.6; % [N]
mu = 1;
mu_dim = mu_star;
m0 = 3000 / m_star * 0.6;
mf_constraint = 3000 / m_star * 0.35;
m_min = 500 / m_star; % dependent on a lot
t0 = 11.2 * year_to_sec / t_star;
ToF = 0.4 * year_to_sec / t_star;
tf = ToF;
tf_actual = t0 + ToF;
N = 15;

dataset_filename = strrep(sprintf("dataset_%.1fToF_%.1fyr_%.2fm", ToF * t_star / year_to_sec, t0 * t_star / year_to_sec, m0 / 3000 * m_star), '.', 'p');

%% Calculate max dV possible for continuous max thrust (ignoring external forces)
Isp = 4000; % [s]
g_0 = 9.80665; % [m / s2]
alpha = 1 / (Isp * g_0); % [s / m]

mf = m0 - alpha * u_max * tf * t_star / m_star;
dV_max = Isp * g_0 * log(m0 / mf) / 1000 / v_star;

%%

u_hold = "FOH";
Nu = (u_hold == "ZOH") * (N - 1) + (u_hold == "FOH") * N;

parser = "CVXPyGEN";
nx = 7;
nu = 3;
np = 0;

%cvxpy_params = [T_max, ...]

initial_guess = "Lambert"; % "straight line" or "Lambert"
surrogate = "PCE";

ptr_ops.iter_max = 5;
ptr_ops.iter_min = 1;
ptr_ops.Delta_min = 5e-3;
ptr_ops.w_vc = 1e2;
ptr_ops.w_tr = ones(1, Nu) * 1e-6;
ptr_ops.w_tr_p = 0;
ptr_ops.update_w_tr = false;
ptr_ops.delta_tol = 1e-2;
ptr_ops.q = 2;
ptr_ops.alpha_x = 1;
ptr_ops.alpha_u = 1;
ptr_ops.alpha_p = 0;

scale = false;

f = @(t, x, u, p) f_kepler_fixedtf(t, x, u, p);

min_mass_constraint = {1:N, @(t, x, u, p) m_min - x(7)};

max_thrust_constraint = {1:N, @(t, x, u, p) norm(u, 2) - u_max};

convex_constraints = {min_mass_constraint, max_thrust_constraint};


tspan = [0, tf];
t_k = linspace(tspan(1), tspan(2), N);
delta_t = t_k(2) - t_k(1);

if u_hold == "ZOH"
    min_fuel_objective = @(x, u, p, x_ref, u_ref, p_ref) alpha / m_star * t_star * sum(norms(u, 2, 1)) * delta_t;
else
    min_fuel_objective = @(x, u, p, x_ref, u_ref, p_ref) alpha / m_star * t_star * sum((norms(u(1:3, 1:(end - 1)), 2, 1) + norms(u(1:3, 2:end), 2, 1)) / 2) * delta_t;
end

%% Asteroid data
load_lambert()

%% Lambertify
ast_data = importdata('GTOC12_Asteroids_Data.txt');
offset = 2;
IDs = 50001 : 51000;
ast.a = ast_data.data(IDs, offset + 1);
ast.e = ast_data.data(IDs, offset + 2);
ast.inc = deg2rad(ast_data.data(IDs, offset + 3));
ast.Omega = deg2rad(ast_data.data(IDs, offset + 4));
ast.omega = deg2rad(ast_data.data(IDs, offset + 5));
ast.M0 = deg2rad(ast_data.data(IDs, offset + 6));

IDs_i = 1 : numel(IDs);

comb_i_full = combinations(IDs_i, IDs_i);
comb_i = comb_i_full(comb_i_full.IDs_i ~= comb_i_full.IDs_i_1, :);

[x_kep_ast, x_cart_ast] = get_cartesian_states(ast, mu, [t0, tf_actual]);

% Ast1 -> Ast2
x_1_AA = x_cart_ast(:, comb_i.IDs_i, 1);
x_2_AA = x_cart_ast(:, comb_i.IDs_i_1, 2);

% Ast -> Ast (zero rev for drop-off)
[v1_best_AA, v2_best_AA, dV_best_AA] = best_lambert_zeroN(x_1_AA, x_2_AA, ToF * ones([1, numel(comb_i.IDs_i)]), 0, 0);

%% Filter Lambert Solutions
max_dV = dV_max;
multiplier = 1;

if surrogate == "PCE"
    % Run surrogate to estimate low thrust dV
    PCE_model = load("Ast2Ast_PCE_ratio_diffnorm_arbitrary.mat").myPCE_ratio;
    dV_PCE = Ast2Ast_PCE_ratio_diffnorm_eval(PCE_model, x_1_AA(4:6, :) - v1_best_AA, x_2_AA(4:6, :) - v2_best_AA, dV_best_AA, m0 * ones([1, numel(dV_best_AA)]), ToF * ones([1, numel(dV_best_AA)]), dV_max * ones([1, numel(dV_best_AA)]));
    dV_filter = find((dV_best_AA < max_dV / multiplier) & (dV_PCE' < max_dV * 0.9));
    dV_best_AA_filtered = dV_PCE(dV_filter)';
elseif surrogate == "Lambert"
    dV_filter = find(dV_best_AA < max_dV / multiplier);
    dV_best_AA_filtered = dV_best_AA(dV_filter);
end

n_guesses = numel(dV_filter)

x_1_AA_filtered = x_1_AA(:, dV_filter);
x_2_AA_filtered = x_2_AA(:, dV_filter);
v1_best_AA_filtered = v1_best_AA(:, dV_filter);
v2_best_AA_filtered = v2_best_AA(:, dV_filter);

%% Create Guesses from Lambert
guesses = {};
N_rev = 0;
for i = 1 : n_guesses
    %guess = lambert_initial_guess(x_1_AA(1:6), x_2_AA(), v1_best, v2_best, N_best, t_k_best, u_max, alpha, t_star, m_star, Isp, g_0, v_star, 6, 0, m0);
    guess_i = lambert_simple_initial_guess(x_1_AA_filtered(1:6, i), x_2_AA_filtered(:, i), v1_best_AA_filtered(:, i), v2_best_AA_filtered(:, i), N_rev, t_k, m0);
    guesses.x(:, :, i) = guess_i.x;

    if u_hold == "FOH"
       guess_i.u = [guess_i.u, [0;0;0] + 1e-5];
    end

   guesses.u(:, :, i) = guess_i.u;
end
guesses.p = zeros([0, n_guesses]);

%%
unload_lambert()


%% solve
guess_0.x = guesses.x(:, :, 1);
guess_0.u = guesses.u(:, :, 1);
guess_0.p = guesses.p(:, 1);
problem = DeterministicProblem([x_1_AA_filtered(1:6, 1); m0], x_2_AA_filtered(1:6, 1), N, u_hold, tf, f, guess_0, convex_constraints, min_fuel_objective, scale = scale, integration_tolerance = 1e-12, discretization_method = "errorRK4_kepler_fixedtf", N_sub = 1, Name = "Ast2Ast_fixedmf");

[problem, Delta_disc] = problem.discretize(guess_0.x, guess_0.u, guess_0.p);

%%
t1 = tic;

ptr_sols_x = {};
ptr_sols_u = {};
ptr_sols_p = {};
converged_is = {};
batch_size = 500;
for i = 1 : ceil(n_guesses / batch_size)
    converged_is_batch = zeros([1, batch_size]);
    ptr_sols_batch_x = zeros(nx, N, batch_size); 
    ptr_sols_batch_u = zeros(nu, Nu, batch_size); 
    ptr_sols_batch_p = zeros(np, batch_size); 
    j_end = batch_size;
    for j = 1 : batch_size
        index = (i - 1) * batch_size + j;
        if index > n_guesses
            j_end = j - 1;
            break
        end
        problem_new = problem;
        problem_new.x0 = x_1_AA_filtered(1:6, index);
        problem_new.xf = [x_2_AA_filtered(1:6, index); mf_constraint];
        problem_new.initial_bc = @(x, p) [x(1:6) - problem_new.x0(1:6); 0];
        problem_new.terminal_bc = @(x, p, x_ref, p_ref) x - problem_new.xf;
        problem_new.guess.x = guesses.x(:, :, index);
        problem_new.guess.u = guesses.u(:, :, index);
        problem_new.guess.p = guesses.p(:, index);

        ptr_sol_index = ptr(problem_new, ptr_ops, parser, quiet = 2);
        converged_is_batch(j) = ptr_sol_index.converged;

        if converged_is_batch(j)
            ptr_sols_batch_x(:, :, j) = ptr_sol_index.x(:, :, ptr_sol_index.converged_i + 1);
            ptr_sols_batch_u(:, :, j) = ptr_sol_index.u(:, :, ptr_sol_index.converged_i + 1);
            ptr_sols_batch_p(:, :, j) = ptr_sol_index.p(:, ptr_sol_index.converged_i + 1);
        end
    end
    converged_is{i} = converged_is_batch(1 : j_end);
    ptr_sols_x{i} = ptr_sols_batch_x(:, :, 1 : j_end);
    ptr_sols_u{i} = ptr_sols_batch_u(:, :, 1 : j_end);
    ptr_sols_p{i} = ptr_sols_batch_p(:, 1 : j_end);
end
converged_is = find([converged_is{:}]);

ptr_sols = {};
ptr_sols.x = zeros(nx, N, numel(converged_is));
ptr_sols.u = zeros(nu, Nu, numel(converged_is));
ptr_sols.p = zeros(np, numel(converged_is));
for b = 1 : ceil(n_guesses / batch_size)
    n_converged_batch = size(ptr_sols_x{b}, 3);
    ptr_sols.x(:, :, (1 : n_converged_batch) + (b - 1) * batch_size) = ptr_sols_x{b};
    ptr_sols.u(:, :, (1 : n_converged_batch) + (b - 1) * batch_size) = ptr_sols_u{b};
    ptr_sols.p(:, (1 : n_converged_batch) + (b - 1) * batch_size) = ptr_sols_p{b};
end
  
% ptr_sols = {}; 
% converged_is = [];
% parfor i = 1 : n_guesses
%     problem_new = problem;
%     problem_new.x0 = [x_1_AA_filtered(1:6, i); m0];
%     problem_new.xf = x_2_AA_filtered(1:6, i);
%     problem_new.initial_bc = @(x, p) x - problem_new.x0;
%     problem_new.terminal_bc = @(x, p, x_ref, p_ref) [x(1:6) - problem_new.xf; 0];
%     problem_new.guess.x = guesses.x(:, :, i);
%     problem_new.guess.u = guesses.u(:, :, i);
%     problem_new.guess.p = guesses.p(:, i);
% 
%     ptr_sols{i} = ptr(problem_new, ptr_ops, parser, quiet = 2);
%     converged_is = [converged_is, ptr_sols{i}.converged];
% end
% converged_is = find(converged_is);

t2 = toc(t1);

fprintf("%g transfers in %.3f seconds for %.3f transfers/s with %.3f%% successful\n", n_guesses, t2, n_guesses / t2, numel(converged_is) / n_guesses * 100)

numel(converged_is)
%%
dV_rocket_equation = zeros([1, numel(converged_is)]);
for i = 1 : numel(converged_is)
    dV_rocket_equation(i) = Isp * g_0 * log(ptr_sols.x(7, 1, converged_is(i)) / ptr_sols.x(7, end, converged_is(i))) / 1000 / v_star;
end

dV_ratio = dV_rocket_equation ./ dV_best_AA_filtered(converged_is);

figure
scatter(dV_best_AA_filtered(converged_is) * v_star, dV_rocket_equation * v_star); hold on
yline(dV_max * v_star, Label="Continuous Max Thrusting")
line([0, dV_max * v_star], [0, dV_max * v_star])
xlabel("Lambert dV [km / s]")
ylabel("Low Thrust dV [km / s]")
title("Low Thrust dV vs Lambert dV")
subtitle(sprintf("For %.1f Month Asteroid Transfers at Year %.2f", ToF * t_star / year_to_sec * 12, t0 * t_star / year_to_sec))
grid on
hold off

figure
hist_ratio = histogram(dV_ratio);

pd = fitdist(dV_ratio','gamma');
y1 = gampdf(hist_ratio.BinEdges,pd.a,pd.b);
figure
plot(hist_ratio.BinEdges, y1 / sum(y1)); hold on
stairs(hist_ratio.BinEdges(1:(end-1)), hist_ratio.Values / sum(hist_ratio.Values));
hold off

figure
qqplot(dV_ratio, pd)

%%
% Ast1 -> Ast2
x_1_kep = x_kep_ast(:, comb_i.IDs_i(dV_filter), 1);
x_2_kep = x_kep_ast(:, comb_i.IDs_i_1(dV_filter), 2);

dataset = [];
dataset.dV_lambert = dV_best_AA_filtered(converged_is);
dataset.dV_lowthrust = dV_rocket_equation;
dataset.v1_ast = x_1_AA_filtered(4:6, converged_is);
dataset.v2_ast = x_2_AA_filtered(4:6, converged_is); 
dataset.v1_lambert = v1_best_AA_filtered(:, converged_is);
dataset.v2_lambert = v2_best_AA_filtered(:, converged_is);
dataset.dV_ratio = dV_ratio;
dataset.ToF = ToF;
dataset.t0 = t0;
dataset.x_1 = x_1_kep(:, converged_is);
dataset.x_2 = x_2_kep(:, converged_is);
dataset.m0 = ptr_sols.x(7, 1, converged_is);
dataset.mf = mf_constraint;
dataset.ID1 = IDs(comb_i.IDs_i(dV_filter(converged_is)));
dataset.ID2 = IDs(comb_i.IDs_i_1(dV_filter(converged_is)));
% save(dataset_filename + ".mat", dataset)
%%
%load("dataset_0p8ToF_13p2yr.mat")

%%

figure
scatter3(dataset.dV_lambert, dataset.dV_lowthrust, dataset.x_1(3,:) + dataset.x_2(3,:)); hold on
xlabel("Lambert dV [km / s]")
ylabel("Low Thrust dV [km / s]")
title("Low Thrust dV vs Lambert dV")
subtitle(sprintf("For %.1f Month Asteroid Transfers at Year %.2f", ToF * t_star / year_to_sec * 12, t0 * t_star / year_to_sec))
grid on
hold off

%%
histogram(dataset.x_1(6,:))

%%
ig = converged_is(2);
x = ptr_sols.x(:, :, ig);
u = ptr_sols.u(:, :, ig);
p = ptr_sols.p(:, ig);

i_filter = dV_filter(ig);
ID1 = IDs(comb_i.IDs_i(i_filter));
ID2 = IDs(comb_i.IDs_i_1(i_filter));
[x_kep_0_ast1, M_ast1, E_ast1, nu_ast1, x_keplerian_ast1, x_cartesian_ast1] = get_asteroid(ID1);
[x_kep_0_ast2, M_ast2, E_ast2, nu_ast2, x_keplerian_ast2, x_cartesian_ast2] = get_asteroid(ID2);

% Initial conditions
t_plot = linspace(0, tf, 100) + t0;
x_cartesian_ast1_plot = zeros([6, numel(t_plot)]);
x_cartesian_ast2_plot = zeros([6, numel(t_plot)]);
for k = 1:numel(t_plot)
    x_cartesian_ast1_plot(:, k) = x_cartesian_ast1(t_plot(k));
    x_cartesian_ast2_plot(:, k) = x_cartesian_ast2(t_plot(k));
end

guess.x = guesses.x(:, :, ig);
guess.u = guesses.u(:, :, ig);
guess.p = guesses.p(:, ig);

problem.x0 = [x_1_AA_filtered(:, ig); x(7, 1)];
problem.xf = x_2_AA_filtered(:, ig);
%problem.initial_bc = @(x, p) x - problem.x0;
%problem.terminal_bc = @(x, p, x_ref, p_ref) [x(1:6) - problem.xf; 0];

r = x(1:3, :); v = x(4:6, :);

x_0_opt = problem.x0;

[t_cont_sol, x_cont_sol, u_cont_sol] = problem.cont_prop(u, p, x0 = x_0_opt);
r_cont_sol = x_cont_sol(1:3, :);
v_cont_sol = x_cont_sol(4:6, :);

[t_cont_sol, x_cont_sol, u_cont_sol] = problem.cont_prop(u, p, x0 = x_0_opt);

r_guess = guess.x(1:3, :);

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
legend('Spacecraft', "", "Thrust", 'Guess', "", sprintf("Asteroid %g", ID1), "", sprintf("Asteroid %g", ID2), "", "Start", "End", 'Location', 'northwest'); axis equal; grid on

%%
figure
tiledlayout(1, 2)

nexttile
plot(t_cont_sol(1:end - (N - Nu)), u_cont_sol(1:3,:), LineWidth=1); hold on
plot(t_cont_sol(1:end - (N - Nu)), vecnorm(u_cont_sol(1:3,:)), LineWidth=1)
title("Control")
xlabel("Time")
grid on

nexttile
plot(t_cont_sol(1:end), x_cont_sol(7, :))
title("Mass")
xlabel("Time")
grid on


%% Plot a bunch of solutions
figure
for ic = 1 : 20
    ig = converged_is(round(rand(1) * numel(converged_is)));
    x = ptr_sols.x(:, :, ig);
    u = ptr_sols.u(:, :, ig);
    p = ptr_sols.p(:, ig);
    
    i_filter = dV_filter(ig);
    ID1 = IDs(comb_i.IDs_i(i_filter));
    ID2 = IDs(comb_i.IDs_i_1(i_filter));
    [x_kep_0_ast1, M_ast1, E_ast1, nu_ast1, x_keplerian_ast1, x_cartesian_ast1] = get_asteroid(ID1);
    [x_kep_0_ast2, M_ast2, E_ast2, nu_ast2, x_keplerian_ast2, x_cartesian_ast2] = get_asteroid(ID2);
    
    % Initial conditions
    t_plot = linspace(0, tf, 100) + t0;
    x_cartesian_ast1_plot = zeros([6, numel(t_plot)]);
    x_cartesian_ast2_plot = zeros([6, numel(t_plot)]);
    for k = 1:numel(t_plot)
        x_cartesian_ast1_plot(:, k) = x_cartesian_ast1(t_plot(k));
        x_cartesian_ast2_plot(:, k) = x_cartesian_ast2(t_plot(k));
    end
    
    guess.x = guesses.x(:, :, ig);
    guess.u = guesses.u(:, :, ig);
    guess.p = guesses.p(:, ig);
    
    problem.x0 = [x_1_AA_filtered(:, ig); x(7, 1)];
    problem.xf = x_2_AA_filtered(:, ig);
    
    r = x(1:3, :); v = x(4:6, :);
    
    x_0_opt = problem.x0;
    
    [t_cont_sol, x_cont_sol, u_cont_sol] = problem.cont_prop(u, p, x0 = x_0_opt);
    r_cont_sol = x_cont_sol(1:3, :);
    v_cont_sol = x_cont_sol(4:6, :);
    
    [t_cont_sol, x_cont_sol, u_cont_sol] = problem.cont_prop(u, p, x0 = x_0_opt);
    
    r_guess = guess.x(1:3, :);
    
    plot_cartesian_orbit(r_cont_sol(1:3,:)', 'k', 0.4, 1); hold on
    quiver3(r(1, 1:Nu), r(2, 1:Nu), r(3, 1:Nu), u(1, :), u(2, :), u(3, :), 0.2, "filled", Color = "red")
    plot_cartesian_orbit(r_guess(1:3,:)', 'g', 0.4, 1); hold on
    plot_cartesian_orbit(x_cartesian_ast1_plot(1:3, :)', 'b', 0.3, 1)
    plot_cartesian_orbit(x_cartesian_ast2_plot(1:3, :)', 'cyan', 0.3, 1)
    scatter3(x_cartesian_ast1_plot(1, 1), x_cartesian_ast1_plot(2, 1), x_cartesian_ast1_plot(3, 1), "green")
    scatter3(x_cartesian_ast2_plot(1, end), x_cartesian_ast2_plot(2, end), x_cartesian_ast2_plot(3, end), "red")
end
plotOrbit3(0, 0, 0, 1, 0, 0 : 0.01 : 2 * pi, "m", 1, 1, [0;0;0], false, 1)
title('Optimal Asteroid -> Asteroid Transfer Trajectories')
xlabel('X [AU]'); ylabel('Y [AU]'); zlabel('Z [AU]')
grid on
axis equal

%% Compare dV used with rocket equation estimate
if u_hold == "ZOH"
    dV_cont = sum(vecnorm(u_cont_sol) ./ (x_cont_sol(7, 1 : (end - 1)) * m_star) .* diff(t_cont_sol)' * t_star / 1000 / v_star); % delta V
elseif u_hold == "FOH"
    dV_cont = sum(((vecnorm(u_cont_sol(:, 1 : (end - 1))) ./ (x_cont_sol(7, 1 : (end - 1)) * m_star) + vecnorm(u_cont_sol(:, 2 : end))) ./ (x_cont_sol(7, 2 : end) * m_star)) / 2 .* diff(t_cont_sol)' * t_star / 1000 / v_star); % delta V
end

dV_rocket_equation = Isp * g_0 * log(problem.x0(7) / x(7, end)) / 1000 / v_star;

rel_dV_error_perc_rocket_equation = (dV_cont - dV_rocket_equation) / dV_cont * 100

low_thrust_over_lambert = dV_rocket_equation / dV_best_AA_filtered(ig)

%% Test Surrogate
PCE_model = load("Ast2Ast_PCE_ratio_diffnorm_arbitrary.mat").myPCE_ratio;

% Just on successful runs
dV_PCE_success = Ast2Ast_PCE_ratio_diffnorm_eval(PCE_model, dataset.v1_ast - dataset.v1_lambert, dataset.v2_ast - dataset.v2_lambert, dataset.dV_lambert, m0 * ones([1, numel(converged_is)]), ToF * ones([1, numel(converged_is)]), dV_max * ones([1, numel(converged_is)]));

not_converged_is = find(~ismember(1 : n_guesses, converged_is));

% On full dataset
dV_PCE_failure = Ast2Ast_PCE_ratio_diffnorm_eval(PCE_model, x_1_AA_filtered(4:6, not_converged_is) - v1_best_AA_filtered(:, not_converged_is), x_2_AA_filtered(4:6, not_converged_is) - v2_best_AA_filtered(:, not_converged_is), dV_best_AA_filtered(:, not_converged_is), m0 * ones([1, numel(not_converged_is)]), ToF * ones([1, numel(not_converged_is)]), dV_max * ones([1, numel(not_converged_is)]));

figure
tiledlayout(1, 2)
nexttile
histogram(dV_PCE_success, 20); hold on
histogram(dataset.dV_lowthrust, 20)
title("Successful Runs")

nexttile
histogram(dV_PCE_failure, 20)
title("Failed Runs")

%%

figure
scatter(dataset.dV_lambert * v_star, dataset.dV_lowthrust * v_star); hold on
scatter(dV_PCE_success * v_star, dataset.dV_lowthrust * v_star); hold on
scatter(dV_PCE_failure * v_star, dV_PCE_failure * v_star); hold on
yline(dV_max * v_star, Label="Continuous Max Thrusting")
line([0, dV_max * v_star], [0, dV_max * v_star])
xlabel("Lambert dV [km / s]")
ylabel("Low Thrust dV [km / s]")
title("Low Thrust dV vs Lambert dV")
subtitle(sprintf("For %.1f Month Asteroid Transfers at Year %.2f", ToF * t_star / year_to_sec * 12, t0 * t_star / year_to_sec))
legend("Lambert", "PCE (success)", sprintf("PCE (failure, %.1f%%)", sum(dV_PCE_failure > dV_max) / numel(not_converged_is) * 100))
grid on
hold off
axis equal