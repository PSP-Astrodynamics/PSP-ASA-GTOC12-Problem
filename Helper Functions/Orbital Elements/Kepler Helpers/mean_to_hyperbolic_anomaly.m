function H = mean_to_hyperbolic_anomaly(M,e)
    tol = 1e-12;

    % Solve Kepler's equation M = H - e sinh(H)
    H(1:numel(M)) = M;
    for index = 1:numel(M)
        while abs(M(index) - (H(index) - e * sin(H(index)))) > tol
            H(index) = H(index) - (H(index) - e * sin(H(index)) - M(index)) / (1 - e * cos(H(index)));
        end
    end
end