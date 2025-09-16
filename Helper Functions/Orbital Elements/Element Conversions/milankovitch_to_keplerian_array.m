function [x_keplerian, nu] = milankovitch_to_keplerian_array(x_milankovitch_array, Khat, Ihat, mu)
    
    x_keplerian = zeros(size(x_milankovitch_array, 1), 6);
    nu = zeros(size(x_milankovitch_array, 1), 1);

    for ind = 1:size(x_milankovitch_array, 1)
        x_milankovitch = x_milankovitch_array(ind, :);

        [x_keplerian(ind, :), nu(ind)] = milankovitch_to_keplerian(x_milankovitch, Khat, Ihat, mu);
    end
end