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
r = sym("r", [3, 1]);
v = sym("v", [3, 1]);
m = sym("m", [1, 1]);
x = [r;v;m];

thrust = sym("thrust_accel", [3,1]); % Thrust over mass
u = thrust; % [N] = [kg m / s2]
p = sym("p", [0, 1]);

rdot = v;
vdot = -mu/sqrt(r(1)^2+r(2)^2+r(3)^2)^3*r + u * m_to_km / (m * m_star) / a_star;
mdot = -alpha * sqrt(thrust(1)^2+thrust(2)^2+thrust(3)^2) / m_star * t_star;

xdot = [rdot; vdot; mdot];

% Create equations of motion function for optimizer
matlabFunction(xdot,"File","dynamics","Vars", [{t}; {x}; {u}; {p}]);

% Create equations of motion block for Simulink model
%matlabFunctionBlock('EoM_3DoF/SymDynamics3DoF',xdot,'Vars',[x; u; mass; L; I])

% Create Jacobian functions for Kalman filter
%matlabFunction(j_a,"File","3DoF/SymXJacobian3DoF","Vars",[x; u; mass; L; I]);
%matlabFunction(j_b,"File","3DoF/SymUJacobian3DoF","Vars",[x; u; mass; L; I]);