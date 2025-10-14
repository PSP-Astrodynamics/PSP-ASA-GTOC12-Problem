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