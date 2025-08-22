function x_cartesian = modified_equinoctial_to_cartesian(x_modified_equinoctial,mu)
    p = x_modified_equinoctial(1);
    f = x_modified_equinoctial(2);
    g = x_modified_equinoctial(3);
    h = x_modified_equinoctial(4);
    k = x_modified_equinoctial(5);
    L = x_modified_equinoctial(6);

    q = 1 + f .* cos(L) + g .* sin(L);
    s_sqr = 1 + h .^ 2 + k .^ 2;
    alpha_sqr = h .^ 2 - k .^ 2;

    r = p / q;

    rvec = [r / s_sqr * (cos(L) + alpha_sqr * cos(L) + 2 * h * k * sin(L));
            r / s_sqr * (sin(L) - alpha_sqr * sin(L) + 2 * h * k * cos(L));
            2 * r / s_sqr * (h * sin(L) - k * cos(L))];

    vvec = [-1 / s_sqr * sqrt(mu / p) * (sin(L) + alpha_sqr * sin(L) - 2 * h * k * cos(L) + g - 2 * f * h * k + alpha_sqr * g);
            -1 / s_sqr * sqrt(mu / p) * (-cos(L) + alpha_sqr * cos(L) + 2 * h * k * sin(L) - f + 2 * g * h * k + alpha_sqr * f);
            2 / s_sqr * sqrt(mu / p) * (h * cos(L) + k * sin(L) + f * h + g * k)];

    x_cartesian = [rvec; vvec];
end