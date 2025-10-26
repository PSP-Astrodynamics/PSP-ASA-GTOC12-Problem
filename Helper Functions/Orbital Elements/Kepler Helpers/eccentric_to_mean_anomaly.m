function M = eccentric_to_mean_anomaly(E,e)
    M = E - e .* sin(E);
end