function [A_k, B_k_plus, B_k_minus, S_k, d_k, Delta] = discretize_error_dynamics_FOH_RKV87(f, A, B, S, N, tspan, x_ref, u_ref, s_ref, N_sub)
    % Discretization of the devition from a reference trajectory for a
    % dynamical system assuming FOH control. Use Efficient Verner RK8(7)
    % https://www.sfu.ca/~jverner/RKV87.IIa.Efficient.000000011182-240510.FLOAT6040OnWeb
    % Should have local truncation errof of 0.000000011182
    % so N_sub = 1? Hopefully...

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

    %% RK4  

    t_sub_0 = t(1 : (end - 1));
    t_sub_1 = t(2 : end);

    dt_sub = (t(2) - t(1)) / (N_sub);

    x_k = x_ref(:, 1 : (N - 1));

    u_sub_0 = u_ref(:, 1 : (N - 1));
    u_sub_1 = u_ref(:, 2 : N);

    c = [0, 0.092662, 0.1312230361754017604780747799402406525075, 0.1968345542631026407171121699103609787612, 0.427173, 0.485972, 0.161915, 0.985468, 0.9626977348604540392115664231947926180050, 0.99626, 0.997947, 1, 1];
    a{2} = 0.092662; 
    a{3} = [0.03830746548250284242039554953085778876548, 0.09291557069289891805767923040938286374199];
    a{4} = [0.04920863856577566017927804247759024469030, 0, 0.1476259156973269805378341274327707340709];
    a{5} = [0.2743076085702486894953667699331084997155, 0, -0.9319887203102656329703895298805780048911, 1.084854111740016943475022759947469505176];
    a{6} = [0.06461852970939692178473977038055776659235, 0, 0, 0.2687629213368923356417418162215129378455, 0.1525905489537107425735184133979292955622];
    a{7} = [0.07189155819773216802747111989237192757241, 0, 0, 0.1221265783362549661095644262553368220549, -0.07943550859198561207449556225926957458888, 0.04733237205799847793746001611156082496161];
    a{8} = [-6.073603893714328779581044654669389532243, 0, 0, -73.8956, 11.93985370695273926305714852083567777565, -3.839251541405054537968455811084326767757, 72.85406972816664405449235194491803852435];
    a{9} = [-4.868640079323569115532909137641679122100, 0, 0, -59.18572799975646020086112235306397792921, 9.230819319232425236436363261556755728972, -2.676847914962525780976208768457285096420, 58.45720009994685754009028962323039746457, 0.005894309723726360055153797570581572198272];
    a{10} = [-6.689861899320853351893486767784362717327, 0, 0, -81.44271004053111286646869388606624375878, 13.36778825698397107436768361456719138955, -4.470777638416181156550300441220009175768, 80.23321392161410397716314034458127569922, -0.01313638336212181564579824084323466067556, 0.01174378303219413902745537676538322377075];
    a{11} = [-6.788841955800464091202279324616261399375, 0, 0, -82.65639855934828888595908426400236814314, 13.59973921874899036529372991555792312537, -4.574464055350503753023585975406886448931, 81.41943207216075927716035509139094411649, -0.01416248014826418017596237345824563213708, 0.01375441580835227405704608471667945126391, -0.001111656070581006150219154181785069541859];
    a{12} = [-6.910189846402485729483801895952800612193, 0, 0, -84.14495154176748682468399818934446849309, 13.88512122378983816888937012217322612857, -4.702458788144493296650978281402083070191, 82.87411451529241610017736751027256505872, -0.01645498337198780129448623133684652608689, 0.01644663972162521365153657249183964172873, 0.004275449370796530995842729680318146579263, -0.005902668488222361600852336581750274034670];
    a{13} = [-6.911973921198979615960353484856419992328, 0, 0, -84.16635595878781036984379688648536865215, 13.88834627565582007275122755367241993143, -4.703463178409702575934171709526131267400, 82.89518622207404915885492275044886922215, -0.01020345016228260287805622619295788864042, 0.01427900423230391471526298444108039935137, -0.005814993403397981705034981501491752405078, 0, 0];
    b = [0.04625543159712467285354070519930680076661, 0, 0, 0, 0, 0.3706666165521011182439275381303388440188, 0.2590440824552746577195309846039127860157, -679.9841468175039046601229652340421033215, 49.89161129042053159104301060910837813887, 10271.2352221373124138878446768864811886, -14782.1966063568972805901057042269864062, 0, 5141.37795361606373932252398273750538432, 0]; % Propagation stage
    
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