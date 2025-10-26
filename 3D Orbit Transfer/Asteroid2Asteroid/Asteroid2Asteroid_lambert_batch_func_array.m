function [dataset] = Asteroid2Asteroid_lambert_batch_func_array(ID1, ID2, m0_frac, t0_yr, ToF_yr, paths, options)
arguments
    ID1
    ID2
    m0_frac
    t0_yr
    ToF_yr
    paths
    options.surrogate = "PCE"
    options.thrust_frac = 0.5
    options.plot = false
    options.load_lambert = false
    options.target_ID1_batch_size = 3000
    options.target_filter_batch_size = 1e6
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
m0 = 3000 / m_star * m0_frac;
m_min = 500 / m_star; % dependent on a lot
t0 = t0_yr * year_to_sec / t_star;
ToF = ToF_yr * year_to_sec / t_star;
tf = ToF;
tf_actual = t0 + ToF;
N = 15;

% Create outputs
dV_filter = [];

%% Calculate max dV possible for continuous max thrust (ignoring external forces)
Isp = 4000; % [s]
g_0 = 9.80665; % [m / s2]
alpha = 1 / (Isp * g_0); % [s / m]

mf = m0 - alpha * u_max * tf * t_star / m_star;
dV_max = Isp * g_0 * log(m0 ./ mf) / 1000 / v_star;

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

num_ID1_batch = ceil(numel(IDs_1_i) / options.target_ID1_batch_size);

fprintf("Number of size %g combination batches: %g| Completed:", options.target_ID1_batch_size, num_ID1_batch)

valid_ID1_i = [];
valid_ID1 = [];
valid_ID2 = [];
dV = [];
m0_filtered = [];
num_lambert = 0;

for i_ID1 = 1 : num_ID1_batch
    if i_ID1 < num_ID1_batch
        i_ID1_batch = ((i_ID1 - 1) * options.target_ID1_batch_size + 1) : (i_ID1 * options.target_ID1_batch_size);
    else
        i_ID1_batch = ((i_ID1 - 1) * options.target_ID1_batch_size + 1) : numel(IDs_1_i);
    end

    IDs_1_i_batch = IDs_1_i(i_ID1_batch);
    comb_i = combinations(IDs_1_i_batch, IDs_2_i);
    comb_i = comb_i(ID1(comb_i.IDs_1_i_batch) ~= ID2(comb_i.IDs_2_i), :);
    
    [~, x_cart_ast1] = get_cartesian_states(ast1, mu, t0);
    [~, x_cart_ast2] = get_cartesian_states(ast2, mu, tf_actual);

    % Ast1 -> Ast2
    x_1_AA = x_cart_ast1(:, comb_i.IDs_1_i_batch);
    x_2_AA = x_cart_ast2(:, comb_i.IDs_2_i);
    m0_AA = m0(comb_i.IDs_1_i_batch);
    dV_max_AA = dV_max(comb_i.IDs_1_i_batch);
    
    PCE_model = load("Ast2Ast_PCE_ratio_diffnorm_arbitrary.mat").myPCE_ratio;
    
    num_filter_batch = ceil(size(x_1_AA, 2) / options.target_filter_batch_size);
    v1_best_AA_filtered = [];
    v2_best_AA_filtered = [];
    dV_best_AA_filtered = [];
    dV_filter = [];
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
            dV_filter = [dV_filter, i_batch(lambert_filter(PCE_filter))]; 
            v1_best_AA_filtered = [v1_best_AA_filtered, v1_best_AA_batch(:, lambert_filter(PCE_filter))];
            v2_best_AA_filtered = [v2_best_AA_filtered, v2_best_AA_batch(:, lambert_filter(PCE_filter))];
            dV_best_AA_filtered = [dV_best_AA_filtered, dV_PCE(PCE_filter)'];
        elseif surrogate == "Lambert"
            dV_filter = [dV_filter, i_batch(lambert_filter)];
            v1_best_AA_filtered = [v1_best_AA_filtered, v1_best_AA_batch(:, lambert_filter)];
            v2_best_AA_filtered = [v2_best_AA_filtered, v2_best_AA_batch(:, lambert_filter)];
            dV_best_AA_filtered = [dV_best_AA_filtered, dV_best_AA_batch(lambert_filter)];
        end
    end
    valid_ID1_i = [valid_ID1_i, IDs_1_i(comb_i.IDs_1_i_batch(dV_filter))];
    valid_ID1 = [valid_ID1, ID1(comb_i.IDs_1_i_batch(dV_filter))];
    valid_ID2 = [valid_ID2, ID2(comb_i.IDs_2_i(dV_filter))];
    dV = [dV, dV_best_AA_filtered];
    m0_filtered = [m0_filtered, m0_AA(comb_i.IDs_1_i_batch(dV_filter))];
    num_lambert = num_lambert + numel(comb_i.IDs_2_i);

    if i_ID1 ~= num_ID1_batch
        fprintf(sprintf(" %g,", i_ID1))
    else
        fprintf(sprintf(" %g", i_ID1))
    end
end
fprintf("\n")

mf_filtered = rockeq_dV_to_dm(dV * v_star, m0_filtered);

dataset = struct;
dataset.ID1 = valid_ID1;
dataset.ID2 = valid_ID2;
dataset.ID1_i = valid_ID1_i;
dataset.dV_surrogate = dV;
dataset.m0 = m0_filtered;
dataset.mf = mf_filtered;
dataset.num_lambert = num_lambert;

dataset.ID2_unique = unique(dataset.ID2);

mf_avg = zeros(size(dataset.ID2_unique));
for u = 1 : numel(dataset.ID2_unique)
    u_filter = dataset.ID2 == dataset.ID2_unique(u);

    mf_avg(u) = mean(dataset.mf(u_filter));
end

dataset.paths = [paths(:, valid_ID1_i); valid_ID2];


dataset.mf_avg = mf_avg;
end

function [mf] = rockeq_dV_to_dm(dV, m0)
    Isp = 4000; % [s]
    g_0 = 9.80665; % [m / s2]

    mf = m0 .* exp(-dV * 1000 / (Isp * g_0));
end