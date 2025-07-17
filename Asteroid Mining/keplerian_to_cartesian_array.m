function x_cartesian = keplerian_to_cartesian_array(x_keplerian_array,nu_array,mu)
    x_cartesian = zeros(size(x_keplerian_array, 1), 6);

    for ind = 1:size(x_keplerian_array, 1)
        x_keplerian = x_keplerian_array(ind, :);
        
        if isempty(nu_array)
            nu = [];
        else
            nu = nu_array(ind);
        end

        x_cartesian(ind, :) = keplerian_to_cartesian(x_keplerian, nu, mu);
    end
end