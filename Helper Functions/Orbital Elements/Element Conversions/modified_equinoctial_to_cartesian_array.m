function x_cartesian = modified_equinoctial_to_cartesian_array(x_modified_equinoctial_array,mu)
    x_cartesian = zeros(size(x_modified_equinoctial_array, 1), 6);

    for ind = 1:size(x_modified_equinoctial_array, 1)
        x_modified_equinoctial = x_modified_equinoctial_array(ind, :);

        x_cartesian(ind, :) = modified_equinoctial_to_cartesian(x_modified_equinoctial, mu);
    end
end