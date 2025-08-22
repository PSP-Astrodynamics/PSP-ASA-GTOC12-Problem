function [x_keplerian, nu] = modified_equinoctial_to_keplerian_array(x_modified_equinoctial_array)
    x_keplerian = zeros(size(x_modified_equinoctial_array, 1), 6);
    nu = zeros(size(x_modified_equinoctial_array, 1), 1);
    
    for ind = 1:size(x_modified_equinoctial_array, 1)
        x_modified_equinoctial = x_modified_equinoctial_array(ind, :);

        [x_keplerian(ind, :), nu(ind)] = modified_equinoctial_to_keplerian(x_modified_equinoctial);
    end
end