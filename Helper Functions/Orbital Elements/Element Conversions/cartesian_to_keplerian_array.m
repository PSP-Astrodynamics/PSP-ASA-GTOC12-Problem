function [x_keplerian, nu] = cartesian_to_keplerian_array(x_cartesian_array, Khat, Ihat, mu)
%CARTESIAN_TO_KEPLERIAN_ARRAY Summary of this function goes here
%   Detailed explanation goes here
    x_keplerian = zeros(size(x_cartesian_array, 1), 6);
    nu = zeros([size(x_cartesian_array, 1), 1]);

    for ind = 1:size(x_cartesian_array, 1)
        x_cartesian = x_cartesian_array(ind, :);

        [x_keplerian(ind, :), nu(ind)] = cartesian_to_keplerian(x_cartesian, Khat, Ihat, mu);
    end
end