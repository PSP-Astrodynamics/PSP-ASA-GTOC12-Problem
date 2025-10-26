function [x_keplerian, nu] = milankovitch_to_keplerian(x_milankovitch,Khat,Ihat,mu)
    hvec = x_milankovitch(1:3);
    evec = x_milankovitch(4:6);
    L = x_milankovitch(7);

    h = norm(hvec);
    e = norm(evec);
    p = h ^ 2 / mu;
    a = p / (1 - e ^ 2);
    nvec = cross(Khat, hvec);
    n = norm(nvec);
    i = acos(dot(hvec, Khat) / h); % QUADRANT? Always < pi
    Omega_sign = 1 - 2 * (nvec(2) < 0);
    Omega = acos(dot(nvec, Ihat) / n) * Omega_sign; % QUADRANT? If n(2) > 0 then < pi
    omega_sign = 1 - 2 * (evec(3) < 0);
    omega = acos(dot(nvec, evec) / (n * e)) * omega_sign; % QUADRANT? If e(3) > 0 then < pi
    nu = L - (Omega + omega);
    M = eccentric_to_mean_anomaly(true_to_eccentric_anomaly(nu, e), e);
    
    x_keplerian = [a; e; i; Omega; omega; M];
end