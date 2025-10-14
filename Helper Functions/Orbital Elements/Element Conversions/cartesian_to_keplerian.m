function [x_keplerian, nu] = cartesian_to_keplerian(x_cartesian, Khat, Ihat, mu)
%CARTESIAN_TO_KEPLERIAN Summary of this function goes here
%   Detailed explanation goes here

    rvec = x_cartesian(1:3);
    vvec = x_cartesian(4:6);

    r = norm(rvec);
    v = norm(vvec);

    hvec = cross(rvec, vvec);
    h = norm(hvec);
    evec = 1 / mu * ((v ^ 2 - mu / r) * rvec - dot(rvec, vvec) * vvec);
    e = norm(evec);
    nvec = cross(Khat, hvec);
    n = norm(nvec);
    i = acos(dot(hvec, Khat) / h); % QUADRANT? Always < pi
    Omega_sign = 1 - 2 * (nvec(2) < 0);
    Omega = acos(dot(nvec, Ihat) / n) * Omega_sign; % QUADRANT? If n(2) > 0 then < pi
    omega_sign = 1 - 2 * (evec(3) < 0);
    omega = acos(dot(nvec, evec) / (n * e)) * omega_sign; % QUADRANT? If e(3) > 0 then < pi
    nu_sign = 1 - 2 * (dot(rvec, vvec) < 0);
    nu = acos(dot(evec, rvec) / (e * r)) * nu_sign; % QUADRANT? If dot(r, v) > 0 then < pi
    
    a = semimajor_from_r_v_mu(r, v, mu);
    if e < 1
        M = eccentric_to_mean_anomaly(true_to_eccentric_anomaly(nu, e), e);
    else
        M = hyperbolic_to_mean_anomaly(true_to_hyperbolic_anomaly(nu, e), e); % not implemented
    end

    x_keplerian = [a; e; i; Omega; omega; M];
end

