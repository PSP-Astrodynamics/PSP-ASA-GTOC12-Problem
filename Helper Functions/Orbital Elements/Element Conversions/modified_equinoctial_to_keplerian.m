function [x_keplerian, nu] = modified_equinoctial_to_keplerian(x_modified_equinoctial)
%MODIFIED_EQUINOCTIAL_TO_KEPLERIAN Summary of this function goes here
%   Detailed explanation goes here

p = x_modified_equinoctial(1);
f = x_modified_equinoctial(2);
g = x_modified_equinoctial(3);
h = x_modified_equinoctial(4);
k = x_modified_equinoctial(5);
L = x_modified_equinoctial(6);

a = p / (1 - f ^ 2 - g ^ 2);
e = sqrt(f ^ 2 + g ^ 2);
i = atan2(2 * sqrt(h ^ 2 + k ^ 2), 1 - h ^ 2 - k ^ 2);
Omega = atan2(k, h);
omega = atan2(g * h - f * k, f * h + g * k);
nu = L - (Omega + omega);
M = eccentric_to_mean_anomaly(true_to_eccentric_anomaly(nu, e), e);

x_keplerian = [a; e; i; Omega; omega; M];
end

