function [x_kep_ast, x_cart_ast] = get_cartesian_states(ast, mu, t)   
    x_kep_ast = zeros([6, numel(ast.a), numel(t)]);
    x_cart_ast = zeros([6, numel(ast.a), numel(t)]);

    for i = 1 : numel(t)
        M_ast = sqrt(mu ./ ast.a .^ 3) * t(i) + ast.M0;
        x_kep_ast(:, :, i) = [ast.a'; ast.e'; ast.inc'; ast.Omega'; ast.omega'; M_ast'];
        x_cart_ast(:, :, i) = keplerian_to_cartesian_array(x_kep_ast(:, :, i)', [], mu)';
    end
end