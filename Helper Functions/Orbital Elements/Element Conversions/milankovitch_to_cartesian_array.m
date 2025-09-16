function [x_cartesian] = milankovitch_to_cartesian_array(x_milankovitch_array, Khat, Ihat, mu)
    
    x_cartesian = zeros(size(x_milankovitch_array, 1), 6);

    for ind = 1:size(x_milankovitch_array, 1)
        x_milankovitch = x_milankovitch_array(ind, :);

        x_cartesian(ind, :) = milankovitch_to_cartesian(x_milankovitch, Khat, Ihat, mu);
    end
end