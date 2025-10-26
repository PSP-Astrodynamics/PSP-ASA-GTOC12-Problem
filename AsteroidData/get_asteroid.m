function [x_kep_0, M_ast, E_ast, nu_ast, x_keplerian_ast, x_cartesian_ast] = get_asteroid(ID)
%GET_ASTEROID_FUNCS Summary of this function goes here
%   Detailed explanation goes here
arguments
    ID % Asteroid ID, integer in [1, 60000]
end

y=importdata('GTOC12_Asteroids_Data.txt');

offset = 2;
a_ast = y.data(ID, offset + 1);
e_ast = y.data(ID, offset + 2);
inc_ast = y.data(ID, offset + 3)*pi/180;
Omega_ast = y.data(ID, offset + 4)*pi/180;
omega_ast = y.data(ID, offset + 5)*pi/180;
M_ast0 = deg2rad(y.data(ID, offset + 6));

x_kep_0 = [a_ast; e_ast; inc_ast; Omega_ast; omega_ast; M_ast0];

mu = 1;
M_ast = @(t) sqrt(mu / a_ast^3) * t + M_ast0;
E_ast = @(t) mean_to_eccentric_anomaly(M_ast(t), e_ast);
nu_ast = @(t) eccentric_to_true_anomaly(E_ast(t), e_ast);

x_keplerian_ast = @(t) [x_kep_0(1:5); M_ast(t)];
x_cartesian_ast = @(t) keplerian_to_cartesian(x_keplerian_ast(t), [], mu);

end