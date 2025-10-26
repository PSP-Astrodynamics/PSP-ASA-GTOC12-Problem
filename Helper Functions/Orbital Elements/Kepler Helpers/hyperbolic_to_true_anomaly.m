function nu = hyperbolic_to_true_anomaly(H,e)
    nu = atanh2(sinh(H) .* sqrt(e .^ 2 - 1), (cosh(H) - e));
end