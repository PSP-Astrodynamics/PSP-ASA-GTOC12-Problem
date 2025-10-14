function H = true_to_hyperbolic_anomaly(nu,e)
    H = atanh2(sinh(nu) .* sqrt(e .^ 2 - 1), (cosh(nu) + e));
end