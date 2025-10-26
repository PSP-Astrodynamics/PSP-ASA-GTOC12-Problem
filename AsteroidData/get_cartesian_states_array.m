function [x_kep_ast, x_cart_ast] = get_cartesian_states_array(ast, mu, t)   
    x_kep_ast = zeros([6, numel(ast.a), size(t, 2), size(t, 1)]);
    x_cart_ast = zeros([6, numel(ast.a), size(t, 2), size(t, 1)]);

    for i = 1 : size(t, 2)
        for j = 1 : size(t, 1)
            M_ast = sqrt(mu ./ ast.a .^ 3) * t(j, i) + ast.M0;
            x_kep_ast(:, :, i, j) = [ast.a'; ast.e'; ast.inc'; ast.Omega'; ast.omega'; M_ast'];
            x_cart_ast(:, :, i, j) = keplerian_to_cartesian_array(x_kep_ast(:, :, i, j)', [], mu)';
        end
    end
end