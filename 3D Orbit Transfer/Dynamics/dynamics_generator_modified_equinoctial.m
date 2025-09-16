%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% AAE 590ACA
% Stochastic SCP Rocket Landing Project
% Author: Travis Hastreiter 
% Created On: 6 April, 2025
% Description: 3DoF rocket landing dynamics with changing mass
% Most Recent Change: 6 April, 2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mu = 1;
Isp = 4000; % [s]
g_0 = 9.80665; % [m / s2]
alpha = 1 / (Isp * g_0); % [s / m]

mu_star = 1.32712440018e11; % [km3 / s2]
l_star = 1.49579151285e8; % [km] one AU
m_star = 3000; % [kg]
a_star = mu_star / l_star ^ 2; % [km / s2]
t_star = sqrt(l_star ^ 3 / mu_star);

m_to_km = 1e-3;

t = sym("t");
x_me = sym("x_me", [6, 1]);
m = sym("m", [1, 1]);
x = [x_me; m];

thrust = sym("thrust", [3,1]); % Thrust - in RTN frame!!
u = thrust;
p = sym("p", [0, 1]);

f_0 = f0_modified_equinoctial(x_me, mu);
B = B_modified_equinoctial(x_me, mu);

a_u = u * m_to_km / (m * m_star) / a_star;

x_me_dot = gauss_planetary_eqn(f_0, B, a_u);

mdot = -alpha * sqrt(thrust(1)^2+thrust(2)^2+thrust(3)^2) / m_star * t_star;

xdot = [x_me_dot; mdot];

% Create equations of motion function for optimizer
matlabFunction(xdot,"File","dynamics_modified_equinoctial","Vars", [{t}; {x}; {u}; {p}]);

% Create equations of motion block for Simulink model
%matlabFunctionBlock('EoM_3DoF/SymDynamics3DoF',xdot,'Vars',[x; u; mass; L; I])

% Create Jacobian functions for Kalman filter
%matlabFunction(j_a,"File","3DoF/SymXJacobian3DoF","Vars",[x; u; mass; L; I]);
%matlabFunction(j_b,"File","3DoF/SymUJacobian3DoF","Vars",[x; u; mass; L; I]);

function [f_0] = f0_modified_equinoctial(x, mu)
    p = x(1, :);
    f = x(2, :);
    g = x(3, :);
    L = x(6, :);

    q = 1 + f .* cos(L) + g .* sin(L);

    f_0 = [zeros(5, 1); ...
           sqrt(mu * p) .* (q ./ p) .^ 2];
end


function [B] = B_modified_equinoctial(x, mu)
    p = x(1);
    f = x(2);
    g = x(3);
    h = x(4);
    k = x(5);
    L = x(6);

    q = 1 + f * cos(L) + g * sin(L);
    s_sqr = 1 + h ^ 2 + k ^ 2;

    cons_1 = (h * sin(L) - k * cos(L)) / q;
    B = sqrt(p / mu) * [0, 2 * p / q, 0;
        sin(L), ((q + 1) * cos(L) + f) / q, -g * cons_1;
        -cos(L), ((q + 1) * sin(L) + g) / q, f * cons_1;
        0, 0, s_sqr / (2 * q) * cos(L);
        0, 0, s_sqr / (2 * q) * sin(L);
        0, 0, cons_1];
end


function [x_dot] = gauss_planetary_eqn(f_0, B, a_d)
    x_dot = f_0 + B * a_d;
end