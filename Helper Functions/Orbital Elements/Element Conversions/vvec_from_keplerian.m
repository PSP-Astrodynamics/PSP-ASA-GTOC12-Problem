function vvec = vvec_from_keplerian(x_keplerian,nu,rvec,mu)
    a = x_keplerian(1);
    e = x_keplerian(2);
    i = x_keplerian(3);
    Omega = x_keplerian(4);
    omega = x_keplerian(5);
    M = x_keplerian(6);

    if isempty(nu)
        nu = eccentric_to_true_anomaly(mean_to_eccentric_anomaly(M, e), e);
    end

    if isempty(rvec)
        rvec = rvec_from_keplerian(x_keplerian, nu);
    end

    r = norm(rvec);
    rhat = rvec / r;
    
    p = a .* (1 + e) .* (1 - e);
    h = sqrt(mu * p);
    
    v = sqrt(mu * (2 / r - 1 / a));
    gamma = acos(h / (r * v));
    v_theta = cos(gamma) * v;
    v_r = sin(gamma) * v;
    
    C = cartesian_to_RTN_DCM(i, Omega, omega, nu);

    thetahat = C(:, 2);

    vvec = v_r * rhat + v_theta * thetahat;
end