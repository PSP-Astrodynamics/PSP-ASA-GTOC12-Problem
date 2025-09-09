function [v1_best, v2_best, dV_best, N_best] = best_lambert_thruN(x_1, x_2, ToF, N_max, v1_assist, v2_assist)
    % Solve Lambertus Maximus
    Q = size(x_1, 2);
    direction = ones([Q, 1]);

    % First find N (best number of revolutions)
    [v1vec, v2vec, uptoNhave, infoReturnStatus, infoHalfRevStatus] = ivLam_thruN_multipleInputDLL(Q, x_1(1:3, :), x_2(1:3, :), ToF, direction, N_max);
    
    % Retrieve solutions
    [Ns, Qs] = meshgrid(0 : N_max, 1 : Q);
    jcolumn = Ni2col(Ns, Qs, N_max);

    % Filter out NaN and 0 solutions
    vel1_unfiltered = v1vec(1:3,jcolumn(:));
    vel2_unfiltered = v2vec(1:3,jcolumn(:));

    v_filter = all(~isnan(vel1_unfiltered), 1) & any(vel1_unfiltered ~= 0, 1) ...
               & all(~isnan(vel2_unfiltered), 1) & any(vel2_unfiltered ~= 0, 1);

    vel1 = vel1_unfiltered(:, v_filter);
    vel2 = vel2_unfiltered(:, v_filter);

    % Calculate delta V
    v1_b = repmat(x_1(4:6, :), 1, (N_max + 1));
    v2_b = repmat(x_2(4:6, :), 1, (N_max + 1));
    dV = 1e5 * ones([Q, N_max + 1]); % Make sure invalid solutions don't get picked
    dV(v_filter) = max(vecnorm(v1_b(:, v_filter) - vel1) - v1_assist, 0) + max(vecnorm(v2_b(:, v_filter) - vel2) - v2_assist, 0);

    % Extract best solution
    [dV_best, best_i] = min(dV, [], 2);
    N_best = best_i - 1;             

    best_q = (1 : Q)' + N_best * Q;
    v1_best = vel1_unfiltered(:, best_q);
    v2_best = vel2_unfiltered(:, best_q);
end