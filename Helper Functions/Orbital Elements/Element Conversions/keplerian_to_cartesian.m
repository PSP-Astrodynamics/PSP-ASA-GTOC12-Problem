function x_cartesian = keplerian_to_cartesian(x_keplerian,nu,mu)
    a = x_keplerian(1);
    e = x_keplerian(2);
    i = x_keplerian(3);
    Omega = x_keplerian(4);
    omega = x_keplerian(5);
    M = x_keplerian(6);

    if isempty(nu)
        nu = eccentric_to_true_anomaly(mean_to_eccentric_anomaly(M, e), e);
    end

    %rvec = rvec_from_keplerian(x_keplerian, nu);
    %vvec = vvec_from_keplerian(x_keplerian, nu, rvec, mu);

    %x_cartesian2 = [rvec; vvec];
    %x_cartesian = x_cartesian2 .* [1; -1; 1; -1; 1; -1];
    x_cartesian = orb2cartOrig(a,e,i,Omega,omega,nu,mu);
end