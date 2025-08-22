function [rvec, r] = rvec_from_keplerian(x_keplerian,nu)
    a = x_keplerian(1);
    e = x_keplerian(2);
    i = x_keplerian(3);
    Omega = x_keplerian(4);
    omega = x_keplerian(5);
    M = x_keplerian(6);

    if isempty(nu)
        nu = eccentric_to_true_anomaly(mean_to_eccentric_anomaly(M, e), e);
    end

    p = a * (1 + e) * (1 - e);
    r = p / (1 + e * cos(nu));
    C = cartesian_to_RTN_DCM(i, Omega, omega, nu);
    rvec = C(:, 1) * r;
end