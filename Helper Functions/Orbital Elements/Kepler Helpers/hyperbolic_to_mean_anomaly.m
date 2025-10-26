function M = hyperbolic_to_mean_anomaly(H,e)
    M = H - e .* sinh(H);
end