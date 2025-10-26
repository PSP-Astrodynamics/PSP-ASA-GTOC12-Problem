function nu = eccentric_to_true_anomaly(E,e)
    nu = atan2(sin(E) .* sqrt(1 - e .^ 2), (cos(E) - e));
end