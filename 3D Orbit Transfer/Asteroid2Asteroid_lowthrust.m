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
m0 = 3000 / m_star * 0.4;
m_min = 500 / m_star; % dependent on a lot
t0 = 13.2 * year_to_sec / t_star;
ToF = 0.5 * year_to_sec / t_star;
tf = ToF;
tf_actual = t0 + ToF;
N = 15;

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
y=importdata('GTOC12_Asteroids_Data.txt');

load_lambert()

%% Lambertify
ast_data = importdata('GTOC12_Asteroids_Data.txt');
offset = 2;
IDs = 1 : 4000;
ast.a = ast_data.data(IDs, offset + 1);
ast.e = ast_data.data(IDs, offset + 2);
ast.inc = deg2rad(ast_data.data(IDs, offset + 3));
ast.Omega = deg2rad(ast_data.data(IDs, offset + 4));
ast.omega = deg2rad(ast_data.data(IDs, offset + 5));
ast.M0 = deg2rad(ast_data.data(IDs, offset + 6));

comb_i_full = combinations(IDs, IDs);
comb_i = comb_i_full(comb_i_full.IDs ~= comb_i_full.IDs_1, :);

[x_kep_ast, x_cart_ast] = get_cartesian_states(ast, mu, [t0, tf_actual]);

% Ast1 -> Ast2
x_1_AA = x_cart_ast(:, comb_i.IDs, 1);
x_2_AA = x_cart_ast(:, comb_i.IDs_1, 2);

% Ast -> Ast (zero rev for drop-off)
[v1_best_AA, v2_best_AA, dV_best_AA] = best_lambert_zeroN(x_1_AA, x_2_AA, ToF * ones([1, numel(comb_i.IDs)]), 0, 0);

%% Filter Lambert Solutions
max_dV = dV_max;
multiplier = 1;
lambert_filter = find(dV_best_AA < max_dV / multiplier);
n_guesses = numel(lambert_filter)

x_1_AA_filtered = x_1_AA(:, lambert_filter);
x_2_AA_filtered = x_2_AA(:, lambert_filter);
v1_best_AA_filtered = v1_best_AA(:, lambert_filter);
v2_best_AA_filtered = v2_best_AA(:, lambert_filter);
dV_best_AA_filtered = dV_best_AA(lambert_filter);

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
% guesses = {};
% guesses_IDs = {};
% guesses_x0 = {};
% guesses_xf = {};
% guesses_ast1_plot = {};
% guesses_ast2_plot = {};
% for ID1 = 1008 : 1008
% %ID1 = 104;
% [x_kep_0_ast1, M_ast1, E_ast1, nu_ast1, x_keplerian_ast1, x_cartesian_ast1] = get_asteroid(ID1);
% 
% scaler = [0, 0, pi/180, pi/180, pi/180, pi/180];
% offset = 2;
% [~, i] = min(vecnorm(scaler .* (y.data(ID1, offset + (1 : 6)) - y.data([1 : (ID1 - 1), (ID1 + 1) : end], offset + (1 : 6))), 2, 2));
% ID2 = i;
% 
% [x_kep_0_ast2, M_ast2, E_ast2, nu_ast2, x_keplerian_ast2, x_cartesian_ast2] = get_asteroid(ID2);
% 
% % Initial conditions
% t_plot = linspace(0, tf, 100) + t0;
% x_cartesian_ast1_plot = zeros([6, numel(t_plot)]);
% x_cartesian_ast2_plot = zeros([6, numel(t_plot)]);
% for k = 1:numel(t_plot)
%     x_cartesian_ast1_plot(:, k) = x_cartesian_ast1(t_plot(k));
%     x_cartesian_ast2_plot(:, k) = x_cartesian_ast2(t_plot(k));
% end
% 
% x_0 = [x_cartesian_ast1(t0); m0];
% x_f = x_cartesian_ast2(tf_actual);
% 
% 
% if initial_guess == "straight line"
%     tofs = [tf];
%     P_ast1 = 2 * pi *sqrt(x_kep_0_ast1(1) ^ 3 / mu);
%     P_ast2 = 2 * pi * sqrt(x_kep_0_ast2(1) ^ 3 / mu);
%     N_guess = tf / ((P_ast1 + P_ast2) / 2);
%     AU_guess = interp1(tspan, [x_kep_0_ast1(1), x_kep_0_ast2(1)]', t_k);
%     nu_guess = interp1(tspan, [nu_ast1(t0), nu_ast2(tf + t0) + 2 * pi * floor(N_guess)]', t_k);
%     r_guess = [AU_guess .* cos(nu_guess); AU_guess .* sin(nu_guess)];
%     r_guess(end + 1, :) = 0;
%     v_guess = v_circ(r_guess, nu_guess, mu);
%     v_guess(end + 1, :) = 0;
%     m_guess = ones(1, N);
% 
%     guess.x = [r_guess; v_guess; m_guess];
%     guess.u = interp1(tspan, ones(3, 2)' * 1e-5, t_k(1:Nu))';
%     guess.p = [];
% elseif initial_guess == "Lambert"
%     tofs = [tf];
%     P_ast1 = 2 * pi *sqrt(x_kep_0_ast1(1) ^ 3 / mu);
%     P_ast2 = 2 * pi * sqrt(x_kep_0_ast2(1) ^ 3 / mu);
%     N_guess = tf / ((P_ast1 + P_ast2) / 2);
%     for i = 1 : numel(tofs)
%         x_f_tofs(:, i) = x_cartesian_ast2(tofs(i) + t0);
%     end
%     [v1_best, v2_best, dV_best, ToF_best, N_best] = best_lambert(repmat(x_0(1:6), 1, numel(tofs)), x_f_tofs, tofs, [floor(N_guess), ceil(N_guess)], 0, 0);
%     N_best = N_best;
%     t_k_best = linspace(0, ToF_best, N);
%     multiplier = 1;
%     [v1_lamb_, v2_lamb_, dV_lamb_, N_lamb_] = best_lambert_thruN(repmat(x_0(1:6), 1, numel(tofs)), x_f_tofs, tofs, ceil(N_guess), 0, 0);
%     % 
%     % 
%     % mf = m0 - alpha * u_max * tofs * t_star / m_star;
%     % dV_max = Isp * g_0 * log(m0 ./ mf) / 1000 / v_star;
%     % 
%     % 
%     % [~, best_i] = min(dV_lamb * multiplier - dV_max);
%     % if dV_lamb(best_i) * multiplier < dV_max(best_i)
%     %     best_i = find(dV_lamb * multiplier < dV_max, 1, "first");
%     % end
%     % dV_best = dV_lamb(best_i);
%     % v1_best = v1_lamb(:, best_i);
%     % v2_best = v2_lamb(:, best_i);
%     % N_best = N_lamb(best_i) + 1;
%     % ToF_best = tofs(best_i);
% 
%     if dV_best * multiplier > dV_max
%         warning("WARNING: Lambert delta V %.1f%% greater than estimated max low thrust delta V", (dV_best - dV_max) / dV_max * 100)
%         %error("WARNING: Lambert delta V %.1f%% greater than estimated max low thrust delta V", (dV_best - dV_max) / dV_max * 100)
%         continue
%     else 
%         fprintf("Candidate: %g ID1, %g ID2 with %.1f%% less than estimated max low thrust delta V \n", ID1, ID2, (dV_max - dV_best) / dV_max * 100)
%         %continue
%     end
% 
%     %guess = lambert_initial_guess(x_0(1:6), x_f_tofs(:, tofs == ToF_best), v1_best, v2_best, N_best, t_k_best, u_max, alpha, t_star, m_star, Isp, g_0, v_star, 6, 0, m0);
%     guess = lambert_simple_initial_guess(x_0(1:6), x_f_tofs(:, tofs == ToF_best), v1_best, v2_best, N_best, t_k_best, m0);
%     guess.p = [];
%     if u_hold == "FOH"
%         guess.u(:, end + 1) = [0;0;0] + 1e-5;
%     end
% elseif initial_guess == "previous solution"
%     guess.x = ptr_sol_prev.x(:, :, ptr_sol.converged_i);
%     guess.u = ptr_sol_prev.u(:, :, ptr_sol.converged_i);
%     guess.p = ptr_sol_prev.p(1:3, ptr_sol.converged_i);
% end
% 
% guesses{end + 1} = guess;
% guesses_IDs{end + 1} = [ID1, ID2];
% guesses_x0{end + 1} = x_0;
% guesses_xf{end + 1} = x_f;
% guesses_ast1_plot{end + 1} = x_cartesian_ast1_plot;
% guesses_ast2_plot{end + 1} = x_cartesian_ast2_plot;
% end
%%
unload_lambert()


%% solve
guess_0.x = guesses.x(:, :, 1);
guess_0.u = guesses.u(:, :, 1);
guess_0.p = guesses.p(:, 1);
problem = DeterministicProblem([x_1_AA_filtered(1:6, 1); m0], x_2_AA_filtered(1:6, 1), N, u_hold, tf, f, guess_0, convex_constraints, min_fuel_objective, scale = scale, integration_tolerance = 1e-12, discretization_method = "errorRK4_kepler_fixedtf", N_sub = 1, Name = "Ast2Ast_fixed");

[problem, Delta_disc] = problem.discretize(guess_0.x, guess_0.u, guess_0.p);

%%
t1 = tic;

ptr_sols_x = {};
ptr_sols_u = {};
ptr_sols_p = {};
converged_is = {};
batch_size = 500;
parfor i = 1 : ceil(n_guesses / batch_size)
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
        problem_new.x0 = [x_1_AA_filtered(1:6, index); m0];
        problem_new.xf = x_2_AA_filtered(1:6, index);
        problem_new.initial_bc = @(x, p) x - problem_new.x0;
        problem_new.terminal_bc = @(x, p, x_ref, p_ref) [x(1:6) - problem_new.xf; 0];
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
x_1_kep = x_kep_ast(:, comb_i.IDs(lambert_filter), 1);
x_2_kep = x_kep_ast(:, comb_i.IDs_1(lambert_filter), 2);

dataset_0p5ToF_13p2yr = [];
dataset_0p5ToF_13p2yr.dV_lambert = dV_best_AA_filtered(converged_is);
dataset_0p5ToF_13p2yr.dV_lowthrust = dV_rocket_equation;
dataset_0p5ToF_13p2yr.v1_ast = x_1_AA_filtered(4:6, converged_is);
dataset_0p5ToF_13p2yr.v2_ast = x_2_AA_filtered(4:6, converged_is); 
dataset_0p5ToF_13p2yr.v1_lambert = v1_best_AA_filtered(:, converged_is);
dataset_0p5ToF_13p2yr.v2_lambert = v2_best_AA_filtered(:, converged_is);
dataset_0p5ToF_13p2yr.dV_ratio = dV_ratio;
dataset_0p5ToF_13p2yr.ToF = ToF;
dataset_0p5ToF_13p2yr.t0 = t0;
dataset_0p5ToF_13p2yr.x_1 = x_1_kep(:, converged_is);
dataset_0p5ToF_13p2yr.x_2 = x_2_kep(:, converged_is);
save dataset_0p5ToF_13p2yr_0p4m.mat dataset_0p5ToF_13p2yr
%%
%load("dataset_0p8ToF_13p2yr.mat")

%%

figure
scatter3(dataset_0p5ToF_13p2yr.dV_lambert, dataset_0p5ToF_13p2yr.dV_lowthrust, dataset_0p5ToF_13p2yr.x_1(3,:) + dataset_0p5ToF_13p2yr.x_2(3,:)); hold on
xlabel("Lambert dV [km / s]")
ylabel("Low Thrust dV [km / s]")
title("Low Thrust dV vs Lambert dV")
subtitle(sprintf("For %.1f Month Asteroid Transfers at Year %.2f", ToF * t_star / year_to_sec * 12, t0 * t_star / year_to_sec))
grid on
hold off

%%
histogram(dataset_0p5ToF_13p2yr.x_1(6,:))

%%
ig = converged_is(1010);
x = ptr_sols.x(:, :, ig);
u = ptr_sols.u(:, :, ig);
p = ptr_sols.p(:, ig);

i_filter = lambert_filter(ig);
ID1 = comb_i.IDs(i_filter);
ID2 = comb_i.IDs_1(i_filter);
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

problem.x0 = [x_1_AA_filtered(:, ig); m0];
problem.xf = x_2_AA_filtered(:, ig);
problem.initial_bc = @(x, p) x - problem.x0;
problem.terminal_bc = @(x, p, x_ref, p_ref) [x(1:6) - problem.xf; 0];

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
    
    i_filter = lambert_filter(ig);
    ID1 = comb_i.IDs(i_filter);
    ID2 = comb_i.IDs_1(i_filter);
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
    
    problem.x0 = [x_1_AA_filtered(:, ig); m0];
    problem.xf = x_2_AA_filtered(:, ig);
    problem.initial_bc = @(x, p) x - problem.x0;
    problem.terminal_bc = @(x, p, x_ref, p_ref) [x(1:6) - problem.xf; 0];
    
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

%% Compare dV used with rocket equation estimate
if u_hold == "ZOH"
    dV_cont = sum(vecnorm(u_cont_sol) ./ (x_cont_sol(7, 1 : (end - 1)) * m_star) .* diff(t_cont_sol)' * t_star / 1000 / v_star); % delta V
elseif u_hold == "FOH"
    dV_cont = sum(((vecnorm(u_cont_sol(:, 1 : (end - 1))) ./ (x_cont_sol(7, 1 : (end - 1)) * m_star) + vecnorm(u_cont_sol(:, 2 : end))) ./ (x_cont_sol(7, 2 : end) * m_star)) / 2 .* diff(t_cont_sol)' * t_star / 1000 / v_star); % delta V
end

dV_rocket_equation = Isp * g_0 * log(problem.x0(7) / x(7, end)) / 1000 / v_star;

rel_dV_error_perc_rocket_equation = (dV_cont - dV_rocket_equation) / dV_cont * 100

low_thrust_over_lambert = dV_rocket_equation / dV_best_AA_filtered(ig)


%% Helper
function [v_guess] = v_circ(r_guess, nu_guess, mu)
    r = vecnorm(r_guess, 2, 1);
    v = sqrt(mu ./ r);
    v_guess = v .* [-sin(nu_guess); cos(nu_guess)];
end


function [v1_best, v2_best, dV_best, ToF_best, N_best] = best_lambert(x_1, x_2, ToF, N, v1_assist, v2_assist)
    % if ToF is an array, will pick lowest dV

    % Solve Lambertus Maximus
    Q = numel(ToF) * 2;
    r1vec = repmat(x_1(1:3), 1, Q);
    r2vec = repmat(x_2(1:3), 1, Q);
    direction = [ones([Q / 2, 1]); -ones(Q / 2, 1)];
    ToF = repmat(ToF, 1, 2);

    N_max = max(N);

    [v1vec,v2vec,uptoNhave,infoReturnStatus,infoHalfRevStatus] = ivLam_thruN_multipleInputDLL(Q, r1vec, r2vec, repmat(ToF, 2, 1), direction, N_max);

    %in order to retrieve solutions, we need the Ni2col() function to get the correct column
            
    % Retrieve solutions
    [Ns, Qs] = meshgrid(N, 1 : Q);
    jcolumn = Ni2col(Ns, Qs, N_max);

    % Filter out NaN and 0 solutions
    vel1_unfiltered = v1vec(1:3,jcolumn(:));
    vel2_unfiltered = v2vec(1:3,jcolumn(:));

    v_filter = all(~isnan(vel1_unfiltered), 1) & any(vel1_unfiltered ~= 0, 1) ...
               & all(~isnan(vel2_unfiltered), 1) & any(vel2_unfiltered ~= 0, 1);

    vel1 = vel1_unfiltered(:, v_filter);
    vel2 = vel2_unfiltered(:, v_filter);

    % Calculate delta V
    v1_b = repmat(x_1(4:6, :), 1, 2 * (N_max + 1));
    v2_b = repmat(x_2(4:6, :), 1, 2 * (N_max + 1));
    dV = max(vecnorm(v1_b(:, v_filter) - vel1) - v1_assist, 0) + max(vecnorm(v2_b(:, v_filter) - vel2) - v2_assist, 0);

    % Extract best solution
    [dV_best, q_best_filtered] = min(dV);
    v1_best = vel1(:, q_best_filtered);
    v2_best = vel2(:, q_best_filtered);

    filter_indices = find(v_filter);
    q_best = mod(filter_indices(q_best_filtered) - 1, Q) + 1;

    N_best = N(ceil(filter_indices(q_best_filtered) / Q));

    ToF_best = ToF(q_best);

    % Package outputs
    % v1_best, v2_best, dV_best, ToF_best, N_best
end

function [guess] = lambert_initial_guess(x_1, x_2, v_1_trans, v_2_trans, N_rev, t_k, u_max, alpha, t_star, m_star, Isp, g_0, v_star, v_1_assist, v_2_assist, m_0)
    % Construct initial guess from lambert solution
    
    x_1_trans = [x_1(1:3); v_1_trans];
    x_2_trans = [x_2(1:3); v_2_trans];

    % Construct transfer orbit
    [x_1_trans_keplerian, thetastar_1_trans] = cartesian_to_keplerian(x_1_trans, [0; 0; 1], [1; 0; 0], 1);
    [x_2_trans_keplerian, thetastar_2_trans] = cartesian_to_keplerian(x_2_trans, [0; 0; 1], [1; 0; 0], 1);

    thetastar_trans = linspace(thetastar_1_trans, thetastar_2_trans + 2 * pi * (thetastar_2_trans < thetastar_1_trans) + N_rev * 2 * pi, numel(t_k));

    transfer_cartesian = keplerian_to_cartesian_array(repmat(x_1_trans_keplerian, 1, numel(t_k))', thetastar_trans, 1)';

    %plot3(transfer_cartesian(1, :), transfer_cartesian(2, :), transfer_cartesian(3, :))

    % Approximate controls
    u_guess = zeros([3, numel(t_k) - 1]); % assume ZOH

    % Assume constant max thrust in dV direction until dV reached
    % Use Tsiolovsky rocket equation
    dV_1_dir = v_1_trans - x_1(4:6);
    dV_1_mag = norm(dV_1_dir);    

    % Propagate forward from beginning to estimate mass and control for
    % departing
    m_guess = zeros([1, numel(t_k)]);
    m_guess(1:end) = m_0;
    dV_1_left = dV_1_mag - v_1_assist / v_star;
    for k = 1 : (numel(t_k) - 1)
        m_guess(k + 1) = m_guess(k) - alpha * u_max * (t_k(k + 1) - t_k(k)) * t_star / m_star;
        dV_1_left = dV_1_left - Isp * g_0 * log(m_guess(k) / m_guess(k + 1)) / 1000 / v_star;

        u_guess(:, k) = u_max * dV_1_dir;

        if dV_1_left < 0
            m_guess((k + 1) : end) = m_guess(k);
            break;
       end
    end

    dV_2_dir = x_2(4:6) - v_2_trans;
    dV_2_mag = norm(dV_2_dir);    

    mf_expected = m_0 * exp(-(dV_1_mag + dV_2_mag - v_1_assist / v_star - v_2_assist / v_star) * v_star * 1000 / Isp / g_0);
    m_guess([end, end - 1]) = mf_expected;

    % Propagate backward from ending to estimate mass and control for
    % arriving
    dV_2_done = dV_2_mag - v_2_assist / v_star;
    for k = (numel(t_k) - 1) : -1 : 2
        delta_m = alpha * u_max * (t_k(k) - t_k(k - 1)) * t_star / m_star;

        if m_guess(k) + delta_m < m_guess(k - 1)
            m_guess(k - 1) = m_guess(k) + delta_m;
            dV_2_done = dV_2_done + Isp * g_0 * log(m_guess(k - 1) / m_guess(k)) / 1000 / v_star;
            
            u_guess(:, k) = u_max * dV_2_dir;
        else
            break;
        end

        if dV_2_done < 0
            break;
        end
    end

    % Package guess
    guess.x = [transfer_cartesian; m_guess];
    guess.u = u_guess + 1e-5;
end

function [guess] = lambert_simple_initial_guess(x_1, x_2, v_1_trans, v_2_trans, N_rev, t_k, m_0)
    % Construct initial guess from lambert solution
    
    x_1_trans = [x_1(1:3); v_1_trans];
    x_2_trans = [x_2(1:3); v_2_trans];

    % Construct transfer orbit
    [x_1_trans_keplerian, thetastar_1_trans] = cartesian_to_keplerian(x_1_trans, [0; 0; 1], [1; 0; 0], 1);
    [x_2_trans_keplerian, thetastar_2_trans] = cartesian_to_keplerian(x_2_trans, [0; 0; 1], [1; 0; 0], 1);

    thetastar_trans = linspace(thetastar_1_trans, thetastar_2_trans + 2 * pi * (thetastar_2_trans < thetastar_1_trans) + N_rev * 2 * pi, numel(t_k));

    transfer_cartesian = keplerian_to_cartesian_array(repmat(x_1_trans_keplerian, 1, numel(t_k))', thetastar_trans, 1)';

    %plot3(transfer_cartesian(1, :), transfer_cartesian(2, :), transfer_cartesian(3, :))

    % Approximate controls
    u_guess = zeros([3, numel(t_k) - 1]); % assume ZOH

    m_guess = zeros([1, numel(t_k)]);
    m_guess(1:end) = m_0;

    % Package guess
    guess.x = [transfer_cartesian; m_guess];
    guess.u = u_guess + 1e-5;
end


function [] = load_lambert()
    dllDirectory_Path = convertStringsToChars(string(cd) + "\LambertSolvers\ivLamV2p41_738416p65617\matlabInterface\lib\");  %at distribution in this file near the driver, otherwise change here.
    
    addpath(dllDirectory_Path) %add the path where the .dll resides
    
    %load the dll and initialize the lambert routines
    iflag=ivLam_initializeDLL(dllDirectory_Path);
    if(iflag~=0)
        return
    else
        disp('coef path and dll path appear correct, data loaded ok!')
    end
end

function [] = unload_lambert()
    iflag= ivLam_unloadDataDLL();
end

function [x_kep_ast, x_cart_ast] = get_cartesian_states(ast, mu, t)   
    x_kep_ast = zeros([6, numel(ast.a), numel(t)]);
    x_cart_ast = zeros([6, numel(ast.a), numel(t)]);

    for i = 1 : numel(t)
        M_ast = sqrt(mu ./ ast.a .^ 3) * t(i) + ast.M0;
        x_kep_ast(:, :, i) = [ast.a'; ast.e'; ast.inc'; ast.Omega'; ast.omega'; M_ast'];
        x_cart_ast(:, :, i) = keplerian_to_cartesian_array(x_kep_ast(:, :, i)', [], mu)';
    end
end