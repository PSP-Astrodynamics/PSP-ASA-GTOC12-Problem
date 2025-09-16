function x_milankovitch = cartesian_to_milankovitch(x_cartesian,Khat,Ihat,mu)
    rvec = x_cartesian(1:3);
    vvec = x_cartesian(4:6);

    r = norm(rvec);

    hvec = cross(rvec, vvec);
    evec = cross(vvec, hvec) / mu - rvec / norm(rvec);
    e = norm(evec);
    nvec = cross(Khat, hvec);
    n = norm(nvec);
    Omega_sign = 1 - 2 * (nvec(2) < 0);
    Omega = acos(dot(nvec, Ihat) / n) * Omega_sign; % QUADRANT? If n(2) > 0 then < pi
    omega_sign = 1 - 2 * (evec(3) < 0);
    omega = acos(dot(nvec, evec) / (n * e)) * omega_sign; % QUADRANT? If e(3) > 0 then < pi
    nu_sign = 1 - 2 * (dot(rvec, vvec) < 0);
    nu = acos(dot(evec, rvec) / (e * r)) * nu_sign; % QUADRANT? If dot(r, v) > 0 then < pi
    L = Omega + omega + nu;

    x_milankovitch = [hvec; evec; L];
end