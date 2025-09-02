function [vel1, vel2, dV] = best_lambert_zeroN(x_1, x_2, ToF, v1_assist, v2_assist)
    Q = size(x_1, 2);
    direction = ones([Q, 1]);
    
    % Solve Lambertus Maximus
    [vel1, vel2, infoReturnStatus, infoHalfRevStatus] = ivLam_zeroRev_multipleInputDLL(Q, x_1(1:3, :), x_2(1:3, :), ToF, direction);

    % Calculate delta V
    dV = max(vecnorm(x_1(4: 6, :) - vel1) - v1_assist, 0) + max(vecnorm(x_2(4:6, :) - vel2) - v2_assist, 0);
end