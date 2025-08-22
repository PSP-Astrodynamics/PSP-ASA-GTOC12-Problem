function x_modified_equinoctial = keplerian_to_modified_equinoctial(x_keplerian,nu)
    a = x_keplerian(1);
    e = x_keplerian(2);
    i = x_keplerian(3);
    Omega = x_keplerian(4);
    omega = x_keplerian(5);
    M = x_keplerian(6);

    if isempty(nu)
        nu = eccentric_to_true_anomaly(mean_to_eccentric_anomaly(M, e), e);
    end

    p = a * (1 - e ^ 2);
    f = e * cos(Omega + omega);
    g = e * sin(Omega + omega);
    h = tan(i / 2) * cos(Omega);
    k = tan(i / 2) * sin(Omega);
    L = Omega + omega + nu;

    x_modified_equinoctial = [p; f; g; h; k; L];
end