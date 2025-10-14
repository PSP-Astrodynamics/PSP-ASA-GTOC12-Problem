function [dataset, ptr_sols, converged_is] = Asteroid2Asteroid_lowthrust_batch_fixedmf_func_array(ID1, ID2, mf_frac, t0_yr, ToF_yr, options)
arguments
    ID1
    ID2
    mf_frac
    t0_yr
    ToF_yr
    options.surrogate = "PCE"
    options.thrust_frac = 0.5
    options.plot = false
    options.load_lambert = false
    options.target_ID2_batch_size = 3000
    options.target_filter_batch_size = 1e6
    options.target_SCP_batch_size = 500
end

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
m0_frac = mf_frac + 0.05;
m0 = 3000 / m_star * m0_frac;
m_min = 500 / m_star; % dependent on a lot
t0 = t0_yr * year_to_sec / t_star;
ToF = ToF_yr * year_to_sec / t_star;
tf = ToF;
tf_actual = t0 + ToF;
N = 15;

% Create outputs
dataset = struct;
dataset.dV_lambert = [];
dataset.dV_lowthrust = [];
dataset.v1_ast = [];
dataset.v2_ast = [];
dataset.v1_lambert = []; 
dataset.v2_lambert = [];
dataset.dV_ratio = [];
dataset.ToF = [];
dataset.t0 = [];
dataset.m0 = [];
dataset.mf = [];
dataset.dV_max = [];
dataset.x_1 = [];
dataset.x_2 = [];
dataset.converged_is = [];
dataset.ID1 = [];
dataset.ID2 = [];

ptr_sols_all = struct;
ptr_sols_all.x = [];
ptr_sols_all.u = [];
ptr_sols_all.p = [];

converged_is_all = [];

%% Calculate max dV possible for continuous max thrust (ignoring external forces)
Isp = 4000; % [s]
g_0 = 9.80665; % [m / s2]
alpha = 1 / (Isp * g_0); % [s / m]

mf = m0 - alpha * u_max * tf * t_star / m_star;
dV_max = Isp * g_0 * log(m0 ./ mf) / 1000 / v_star;

%%

u_hold = "FOH";
Nu = (u_hold == "ZOH") * (N - 1) + (u_hold == "FOH") * N;

parser = "CVXPyGEN";
nx = 7;
nu = 3;
np = 0;

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
if options.load_lambert
    load_lambert()
end

%% Lambertify
ast_data = importdata('GTOC12_Asteroids_Data.txt');
offset = 2;
ast1.a = ast_data.data(ID1, offset + 1);
ast1.e = ast_data.data(ID1, offset + 2);
ast1.inc = deg2rad(ast_data.data(ID1, offset + 3));
ast1.Omega = deg2rad(ast_data.data(ID1, offset + 4));
ast1.omega = deg2rad(ast_data.data(ID1, offset + 5));
ast1.M0 = deg2rad(ast_data.data(ID1, offset + 6));

ast2.a = ast_data.data(ID2, offset + 1);
ast2.e = ast_data.data(ID2, offset + 2);
ast2.inc = deg2rad(ast_data.data(ID2, offset + 3));
ast2.Omega = deg2rad(ast_data.data(ID2, offset + 4));
ast2.omega = deg2rad(ast_data.data(ID2, offset + 5));
ast2.M0 = deg2rad(ast_data.data(ID2, offset + 6));

IDs_1_i = 1 : numel(ID1);
IDs_2_i = 1 : numel(ID2);

num_ID2_batch = ceil(numel(IDs_2_i) / options.target_ID2_batch_size);

fprintf("Number of size %g combination batches: %g\n", options.target_ID2_batch_size, num_ID2_batch)

for i_ID2 = 1 : num_ID2_batch
    if i_ID2 < num_ID2_batch
        i_ID2_batch = ((i_ID2 - 1) * options.target_ID2_batch_size + 1) : (i_ID2 * options.target_ID2_batch_size);
    else
        i_ID2_batch = ((i_ID2 - 1) * options.target_ID2_batch_size + 1) : numel(IDs_2_i);
    end

    IDs_2_i_batch = IDs_2_i(i_ID2_batch);

    comb_i = combinations(IDs_1_i, IDs_2_i_batch);
    comb_i = comb_i(ID1(comb_i.IDs_1_i) ~= ID2(comb_i.IDs_2_i_batch), :);
    
    [x_kep_ast1, x_cart_ast1] = get_cartesian_states(ast1, mu, t0');
    [x_kep_ast2, x_cart_ast2] = get_cartesian_states(ast2, mu, tf_actual');
    
    % Ast1 -> Ast2
    x_1_AA = x_cart_ast1(:, comb_i.IDs_1_i);
    x_2_AA = x_cart_ast2(:, comb_i.IDs_2_i_batch);
    m0_AA = m0(comb_i.IDs_2_i_batch);
    mf_AA = mf_frac(comb_i.IDs_2_i_batch);
    dV_max_AA = dV_max(comb_i.IDs_2_i_batch);

    PCE_model = load("Ast2Ast_PCE_ratio_diffnorm_arbitrary.mat").myPCE_ratio;

    num_filter_batch = ceil(size(x_1_AA, 2) / options.target_filter_batch_size);
    v1_best_AA_filtered = [];
    v2_best_AA_filtered = [];
    dV_filter = zeros([1, size(x_1_AA, 2)]);
    dV_best_AA_filtered = [];
    % Compute filtering in batch because it is memory intensive...
    for i = 1 : num_filter_batch
        if i < num_filter_batch
            i_batch = ((i - 1) * options.target_filter_batch_size + 1) : (i * options.target_filter_batch_size);
        else
            i_batch = ((i - 1) * options.target_filter_batch_size + 1) : size(x_1_AA, 2);
        end
        
        % Ast -> Ast (zero rev for drop-off)
        [v1_best_AA_batch, v2_best_AA_batch, dV_best_AA_batch] = best_lambert_zeroN(x_1_AA(:, i_batch), x_2_AA(:, i_batch), ToF * ones([1, numel(i_batch)]), 0, 0);
    
        % Filter Lambert Solutions
        max_dV = dV_max_AA(i_batch);
        multiplier = 1;
    
        lambert_filter = find(dV_best_AA_batch < max_dV / multiplier);
    
        if options.surrogate == "PCE"
            % Run surrogate to estimate low thrust dV
            dV_PCE = Ast2Ast_PCE_ratio_diffnorm_eval(PCE_model, x_1_AA(4:6, i_batch(lambert_filter)) - v1_best_AA_batch(:, lambert_filter), x_2_AA(4:6, i_batch(lambert_filter)) - v2_best_AA_batch(:, lambert_filter), dV_best_AA_batch(lambert_filter), m0_AA(i_batch(lambert_filter)), ToF * ones([1, numel(lambert_filter)]), max_dV(lambert_filter));
            PCE_filter = (dV_PCE' < max_dV(lambert_filter) * options.thrust_frac);
            dV_filter(i_batch(lambert_filter)) = PCE_filter; 
            v1_best_AA_filtered = [v1_best_AA_filtered, v1_best_AA_batch(:, lambert_filter(PCE_filter))];
            v2_best_AA_filtered = [v2_best_AA_filtered, v2_best_AA_batch(:, lambert_filter(PCE_filter))];
            dV_best_AA_filtered = [dV_best_AA_filtered, dV_PCE(PCE_filter)'];
        elseif surrogate == "Lambert"
            dV_filter(i_batch) = i_batch(lambert_filter);
            v1_best_AA_filtered = [v1_best_AA_filtered, v1_best_AA_batch(:, lambert_filter)];
            v2_best_AA_filtered = [v2_best_AA_filtered, v2_best_AA_batch(:, lambert_filter)];
            dV_best_AA_filtered = [dV_best_AA_filtered, dV_best_AA_batch(lambert_filter)];
        end
    end
    dV_filter = find(dV_filter);
    
    n_guesses = numel(dV_filter)
    
    x_1_AA_filtered = x_1_AA(:, dV_filter);
    x_2_AA_filtered = x_2_AA(:, dV_filter);
    m0_filtered = m0_AA(dV_filter);
    mf_filtered = mf_AA(dV_filter);

    %% Create Guesses from Lambert
    guesses = {};
    N_rev = 0;
    for i = 1 : n_guesses
        %guess = lambert_initial_guess(x_1_AA(1:6), x_2_AA(), v1_best, v2_best, N_best, t_k_best, u_max, alpha, t_star, m_star, Isp, g_0, v_star, 6, 0, m0);
        guess_i = lambert_simple_initial_guess(x_1_AA_filtered(1:6, i), x_2_AA_filtered(:, i), v1_best_AA_filtered(:, i), v2_best_AA_filtered(:, i), N_rev, t_k, m0_filtered(i));
        guesses.x(:, :, i) = guess_i.x;
    
        if u_hold == "FOH"
           guess_i.u = [guess_i.u, [0;0;0] + 1e-5];
        end
    
       guesses.u(:, :, i) = guess_i.u;
    end
    guesses.p = zeros([0, n_guesses]);
    
    if options.load_lambert
        unload_lambert()
    end

    %% solve
    guess_0.x = guesses.x(:, :, 1);
    guess_0.u = guesses.u(:, :, 1);
    guess_0.p = guesses.p(:, 1);
    problem = DeterministicProblem([x_1_AA_filtered(1:6, 1); m0(1)], x_2_AA_filtered(1:6, 1), N, u_hold, tf, f, guess_0, convex_constraints, min_fuel_objective, scale = scale, integration_tolerance = 1e-12, discretization_method = "errorRK4_kepler_fixedtf", N_sub = 1, Name = "Ast2Ast_fixedmf");
    
    [problem, Delta_disc] = problem.discretize(guess_0.x, guess_0.u, guess_0.p);

    %%
    t1 = tic;
    
    ptr_sols_x = {};
    ptr_sols_u = {};
    ptr_sols_p = {};
    converged_is = {};
    parfor i = 1 : ceil(n_guesses / options.target_SCP_batch_size)
        converged_is_batch = zeros([1, options.target_SCP_batch_size]);
        ptr_sols_batch_x = zeros(nx, N, options.target_SCP_batch_size); 
        ptr_sols_batch_u = zeros(nu, Nu, options.target_SCP_batch_size); 
        ptr_sols_batch_p = zeros(np, options.target_SCP_batch_size); 
        j_end = options.target_SCP_batch_size;
        for j = 1 : options.target_SCP_batch_size
            index = (i - 1) * options.target_SCP_batch_size + j;
            if index > n_guesses
                j_end = j - 1;
                break
            end
            problem_new = problem;
            problem_new.x0 = x_1_AA_filtered(1:6, index);
            problem_new.xf = [x_2_AA_filtered(1:6, index); mf_filtered(index)];
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
    
        fprintf("Completed Batch %g out of %g, %g\n", i, ceil(n_guesses / options.target_SCP_batch_size), sum(converged_is_batch(1 : j_end)));
    end
    converged_is = find([converged_is{:}]);
    
    ptr_sols = {};
    ptr_sols.x = zeros(nx, N, numel(converged_is));
    ptr_sols.u = zeros(nu, Nu, numel(converged_is));
    ptr_sols.p = zeros(np, numel(converged_is));
    for b = 1 : ceil(n_guesses / options.target_SCP_batch_size)
        n_converged_batch = size(ptr_sols_x{b}, 3);
        ptr_sols.x(:, :, (1 : n_converged_batch) + (b - 1) * options.target_SCP_batch_size) = ptr_sols_x{b};
        ptr_sols.u(:, :, (1 : n_converged_batch) + (b - 1) * options.target_SCP_batch_size) = ptr_sols_u{b};
        ptr_sols.p(:, (1 : n_converged_batch) + (b - 1) * options.target_SCP_batch_size) = ptr_sols_p{b};
    end
    
    t2 = toc(t1);
    
    fprintf("%g transfers in %.3f seconds for %.3f transfers/s with %.3f%% successful\n", n_guesses, t2, n_guesses / t2, numel(converged_is) / n_guesses * 100)

    %%
    dV_rocket_equation = zeros([1, numel(converged_is)]);
    for i = 1 : numel(converged_is)
        dV_rocket_equation(i) = Isp * g_0 * log(ptr_sols.x(7, 1, converged_is(i)) / ptr_sols.x(7, end, converged_is(i))) / 1000 / v_star;
    end
    
    dV_ratio = dV_rocket_equation ./ dV_best_AA_filtered(converged_is);

    %%
    % Ast1 -> Ast2
    x_1_kep = x_kep_ast1(:, comb_i.IDs_1_i(dV_filter));
    x_2_kep = x_kep_ast2(:, comb_i.IDs_2_i_batch(dV_filter));        

    dataset.dV_lambert = [dataset.dV_lambert, dV_best_AA_filtered(converged_is)];
    dataset.dV_lowthrust = [dataset.dV_lowthrust, dV_rocket_equation];
    dataset.v1_ast = [dataset.v1_ast, x_1_AA_filtered(4:6, converged_is)];
    dataset.v2_ast = [dataset.v2_ast, x_2_AA_filtered(4:6, converged_is)]; 
    dataset.v1_lambert = [dataset.v1_lambert, v1_best_AA_filtered(:, converged_is)];
    dataset.v2_lambert = [dataset.v2_lambert, v2_best_AA_filtered(:, converged_is)];
    dataset.dV_ratio = [dataset.dV_ratio, dV_ratio];
    dataset.ToF = [dataset.ToF, ToF];
    dataset.t0 = [dataset.t0, t0];%(comb_i.IDs_2_i_batch(dV_filter(converged_is)));
    dataset.m0 = [dataset.m0, reshape(ptr_sols.x(7, 1, :), 1, [])];
    dataset.mf = [dataset.mf, mf_frac(comb_i.IDs_2_i_batch(dV_filter(converged_is)))];
    dataset.dV_max = [dataset.dV_max, dV_max(comb_i.IDs_2_i_batch(dV_filter(converged_is)))];
    dataset.x_1 = [dataset.x_1, x_1_kep(:, converged_is)];
    dataset.x_2 = [dataset.x_2, x_2_kep(:, converged_is)];
    dataset.converged_is = [dataset.converged_is, converged_is];
    dataset.ID1 = [dataset.ID1, ID1(comb_i.IDs_1_i(dV_filter(converged_is)))];
    dataset.ID2 = [dataset.ID2, ID2(comb_i.IDs_2_i_batch(dV_filter(converged_is)))];

    ptr_sols_all.x = cat(3, ptr_sols_all.x, ptr_sols.x);
    ptr_sols_all.u = cat(3, ptr_sols_all.u, ptr_sols.u);
    ptr_sols_all.p = [ptr_sols_all.p, ptr_sols.p];

    converged_is_all = [converged_is_all, converged_is];


    %% Plot
    if options.plot
        figure
        scatter(dV_best_AA_filtered(converged_is) * v_star, dV_rocket_equation * v_star); hold on
        yline(dV_max(1) * v_star, Label="Continuous Max Thrusting")
        line([0, dV_max(1) * v_star], [0, dV_max(1) * v_star])
        xlabel("Lambert dV [km / s]")
        ylabel("Low Thrust dV [km / s]")
        title("Low Thrust dV vs Lambert dV")
        subtitle(sprintf("For %.1f Month Asteroid Transfers at Year %.2f", ToF * t_star / year_to_sec * 12, t0 * t_star / year_to_sec))
        grid on
        hold off
        
        figure
        hist_ratio = histogram(dV_ratio);
    end
    
    if options.plot
        %% Plot a bunch of solutions
        figure
        for ic = 1 : min(20, numel(converged_is))
            ig = converged_is(round(rand(1) * numel(converged_is)));
            x = ptr_sols.x(:, :, ig);
            u = ptr_sols.u(:, :, ig);
            p = ptr_sols.p(:, ig);
            
            i_filter = dV_filter(ig);
            ID1_i = ID1(comb_i.IDs_1_i(i_filter));
            ID2_i = ID2(comb_i.IDs_2_i_batch(i_filter));
            [x_kep_0_ast1, M_ast1, E_ast1, nu_ast1, x_keplerian_ast1, x_cartesian_ast1] = get_asteroid(ID1_i);
            [x_kep_0_ast2, M_ast2, E_ast2, nu_ast2, x_keplerian_ast2, x_cartesian_ast2] = get_asteroid(ID2_i);
            
            % Initial conditions
            t_plot = linspace(0, tf, 100) + t0;%(comb_i.IDs_1_i(dV_filter(ig)));
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
    end
end
end