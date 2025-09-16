function [x_modified_equinoctial_array] = cartesian_to_modified_equinoctial_array(x_cartesian_array, Khat, Ihat, mu)
%CARTESIAN_TO_KEPLERIAN_ARRAY Summary of this function goes here
%   Detailed explanation goes here

    [x_keplerian_array, nu] = cartesian_to_keplerian_array(x_cartesian_array, Khat, Ihat, mu);
    [x_modified_equinoctial_array] = keplerian_to_modified_equinoctial_array(x_keplerian_array, nu);
end