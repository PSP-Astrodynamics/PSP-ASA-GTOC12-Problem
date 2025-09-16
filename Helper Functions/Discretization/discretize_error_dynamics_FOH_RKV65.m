function [A_k, B_k_plus, B_k_minus, S_k, d_k, Delta] = discretize_error_dynamics_FOH_RKV65(f, A, B, S, N, tspan, x_ref, u_ref, s_ref, N_sub)
    % Discretization of the devition from a reference trajectory for a
    % dynamical system assuming FOH control. Use Efficient Verner RK6(5)
    % https://www.sfu.ca/~jverner/RKV65.IIIXb.Efficient.00000144617.081204.CoeffsOnlyFLOAT
    % Should have local truncation error of 
    % so N_sub = 1? Hopefully...
    %#codegen

    nx = numel(x_ref(:, 1));
    nu = numel(u_ref(:, 1));
    np = numel(s_ref);

    t = linspace(tspan(1), tspan(2), N);
    dt = t(2) - t(1);

    A_k = zeros([nx, nx, N - 1]);
    for k = 1 : (N - 1)
        A_k(:, :, k) = eye(nx);
    end
    B_k_plus = zeros([nx, nu, N - 1]);
    B_k_minus = zeros([nx, nu, N - 1]);
    S_k = zeros([nx, np, N - 1]);
    d_k = zeros([nx, 1, N - 1]);
    %Delta = zeros([1, N - 1]);

    %% RKV65

    t_sub_0 = t(1 : (end - 1));
    t_sub_1 = t(2 : end);

    dt_sub = (t(2) - t(1)) / (N_sub);

    x_k = x_ref(:, 1 : (N - 1));

    u_sub_0 = u_ref(:, 1 : (N - 1));
    u_sub_1 = u_ref(:, 2 : N);

    c = [0, 0.06, 0.09593333333333333333333333333333333333333, 0.1439, 0.4973, 0.9725, 0.9995, 1, 1];
    a{2} = 0.06; 
    a{3} = [0.01923996296296296296296296296296296296296, 0.07669337037037037037037037037037037037037];
    a{4} = [0.035975, 0, 0.107925];
    a{5} = [1.318683415233148260919747276431735612861, 0, -5.042058063628562225427761634715637693344, 4.220674648395413964508014358283902080483];
    a{6} = [-41.87259166432751461803757780644346812905, 0, 159.4325621631374917700365669070346830453, -122.1192135650100309202516203389242140663, 5.531743066200053768252631238332999150076];
    a{7} = [-54.43015693531650433250642051294142461271, 0, 207.0672513650184644273657173866509835987, -158.6108137845899991828742424365058599469, 6.991816585950242321992597280791793907096, -0.01859723106220323397765171799549294623692];
    a{8} = [-54.66374178728197680241215648050386959351, 0, 207.9528062553893734515824816699834244238, -159.2889574744995071508959805871426654216, 7.018743740796944434698170760964252490817, -0.01833878590504572306472782005141738268361, -0.0005119484997882099077875432497245168395840];
    a{9} = [0.03438957868357036009278820124728322386520, 0, 0, 0.2582624555633503404659558098586120858767, 0.4209371189673537150642551514069801967032, 4.405396469669310170148836816197095664891, -176.4831190242986576151740942499002125029, 172.3641334014150730294022582711902413315];
    b = [0.03438957868357036009278820124728322386520, 0, 0, 0.2582624555633503404659558098586120858767, 0.4209371189673537150642551514069801967032, 4.405396469669310170148836816197095664891, -176.4831190242986576151740942499002125029, 172.3641334014150730294022582711902413315, 0]; % High order, Propagation stage
    bh = [0.04909967648382489730906854927971225836479, 0, 0, 0.2251112229516524153401395320539875329485, 0.4694682253029562039431948525047387412553, 0.8065792249988867707634161808995217981443, 0, -0.6071194891777959797672951465256217122488, 0.05686113944047569241147603178766138153594]; % Low order
    
    stages = numel(c);

    xdot_ki = zeros([nx, N - 1, stages]);
    A_kdot_ki = zeros([nx, nx, N - 1, stages]);
    B_k_plusdot_ki = zeros([nx, nu, N - 1, stages]);
    B_k_minusdot_ki = zeros([nx, nu, N - 1, stages]);
    S_kdot_ki = zeros([nx, np, N - 1, stages]);

    for k = 1:N_sub
        x_est = x_k;
        A_k_est = A_k;
        B_k_plus_est = B_k_plus; 
        B_k_minus_est = B_k_minus;
        S_k_est = S_k;

        t_k = t_sub_0 + dt_sub * (k - 1);

        sigma_plus_k = reshape((t_k + c(1) * dt_sub - t_sub_0) ./ dt, 1, 1, []);
        sigma_minus_k = reshape((t_sub_1 - t_k - c(1) * dt_sub) ./ dt, 1, 1, []);

        u_k = (t_k + c(1) * dt_sub - t_sub_0) ./ dt .* u_sub_0 ...
            + (t_sub_1 - t_k - c(1) * dt_sub) ./ dt .* u_sub_1;

        [xdot_ki(:, :, 1), A_kdot_ki(:, :, :, 1), B_k_plusdot_ki(:, :, :, 1), B_k_minusdot_ki(:, :, :, 1), S_kdot_ki(:, :, :, 1)] = STM_diff_eq_FOH(t_k + c(1) * dt_sub, x_est, A, B, S, f, u_k, s_ref, sigma_plus_k, sigma_minus_k, A_k_est, B_k_plus_est, B_k_minus_est, S_k_est);

        for i = 2 : stages
            sigma_plus_k = reshape((t_k + c(i) * dt_sub - t_sub_0) ./ dt, 1, 1, []);
            sigma_minus_k = reshape((t_sub_1 - t_k - c(i) * dt_sub) ./ dt, 1, 1, []);
    
            u_k = (t_k + c(i) * dt_sub - t_sub_0) ./ dt .* u_sub_0 ...
                + (t_sub_1 - t_k - c(i) * dt_sub) ./ dt .* u_sub_1;
    
            x_est = x_k;
            A_k_est = A_k;
            B_k_plus_est = B_k_plus; 
            B_k_minus_est = B_k_minus;
            S_k_est = S_k;

            for j = 1 : (i - 1)
                x_est = a{i}(j) * dt_sub .* xdot_ki(:, :, j) + x_est;
                A_k_est = a{i}(j) * dt_sub .* A_kdot_ki(:, :, :, j) + A_k_est;
                B_k_plus_est = a{i}(j) * dt_sub .* B_k_plusdot_ki(:, :, :, j) + B_k_plus_est;
                B_k_minus_est = a{i}(j) * dt_sub .* B_k_minusdot_ki(:, :, :, j) + B_k_minus_est;
                S_k_est = a{i}(j) * dt_sub .* S_kdot_ki(:, :, :, j) + S_k_est;
            end

            [xdot_ki(:, :, i), A_kdot_ki(:, :, :, i), B_k_plusdot_ki(:, :, :, i), B_k_minusdot_ki(:, :, :, i), S_kdot_ki(:, :, :, i)] = STM_diff_eq_FOH(t_k + c(i) * dt_sub, x_est, A, B, S, f, u_k, s_ref, sigma_plus_k, sigma_minus_k, A_k_est, B_k_plus_est, B_k_minus_est, S_k_est);
        end

        x_kp1 = x_k;
        A_kp1 = A_k;
        B_kp1_plus = B_k_plus;
        B_kp1_minus = B_k_minus;
        S_kp1 = S_k;

        for j = 1 : stages
            x_kp1 = x_kp1 + dt_sub * b(j) * xdot_ki(:, :, j);
            A_kp1 = A_kp1 + dt_sub * b(j) * A_kdot_ki(:, :, :, j);
            B_kp1_plus = B_kp1_plus + dt_sub * b(j) * B_k_plusdot_ki(:, :, :, j);
            B_kp1_minus = B_kp1_minus + dt_sub * b(j) * B_k_minusdot_ki(:, :, :, j);
            S_kp1 = S_kp1 + dt_sub * b(j) * S_kdot_ki(:, :, :, j);
        end

        x_k = x_kp1;
        A_k = A_kp1;
        B_k_plus = B_kp1_plus;
        B_k_minus = B_kp1_minus;
        S_k = S_kp1;
    end

    d_k = reshape(x_kp1, nx, 1, N - 1) - (pagemtimes(A_k, reshape(x_ref(:, 1 : (N - 1)), nx, 1, N - 1)) ...
        + pagemtimes(B_k_minus, reshape(u_ref(:, 1 : (N - 1)), nu, 1, N - 1)) ...
        + pagemtimes(B_k_plus, reshape(u_ref(:, 2 : N), nu, 1, N - 1)) ...
        + zero_if_empty(pagemtimes(S_k, zero_if_empty(s_ref))));
    
    Delta = x_kp1 - x_ref(:, 2 : N);
end

function [xdot, A_kdot, B_k_plusdot, B_k_minusdot, S_kdot] = STM_diff_eq_FOH(t, x, A, B, S, f, u, s, sigma_plus, sigma_minus, STM, Phi_B_plus, Phi_B_minus, Phi_S)
    n = numel(t);

    A_t = zeros(size(STM));
    B_t = zeros(size(Phi_B_plus));
    S_t = zeros(size(Phi_S));
    xdot = zeros(size(x));
    for k = 1:n
        A_t(:, :, k) = A(t(k), x(:, k), u(:, k), s);
        B_t(:, :, k) = B(t(k), x(:, k), u(:, k), s);
        S_t(:, :, k) = S(t(k), x(:, k), u(:, k), s);
        xdot(:, k) = f(t(k), x(:, k), u(:, k), s);
    end

    A_kdot = pagemtimes(A_t, STM);
    B_k_plusdot = pagemtimes(A_t, Phi_B_plus) + B_t .* sigma_plus;
    B_k_minusdot = pagemtimes(A_t, Phi_B_minus) + B_t .* sigma_minus;
    S_kdot = pagemtimes(A_t, Phi_S) + S_t;
end