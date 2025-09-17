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