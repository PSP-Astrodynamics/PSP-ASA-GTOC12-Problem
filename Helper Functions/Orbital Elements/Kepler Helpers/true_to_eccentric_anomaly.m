function E = true_to_eccentric_anomaly(nu,e)
    E = atan2(sin(nu) .* sqrt(1 - e .^ 2), (cos(nu) + e));
end