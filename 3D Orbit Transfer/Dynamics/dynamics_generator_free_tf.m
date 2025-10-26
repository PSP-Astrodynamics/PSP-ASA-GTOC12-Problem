%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% AAE 590ACA
% Stochastic SCP Rocket Landing Project
% Author: Travis Hastreiter 
% Created On: 6 April, 2025
% Description: 3DoF rocket landing dynamics with changing mass
% Most Recent Change: 6 April, 2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mu = 1;

t = sym("t");
r = sym("r", [2, 1]);
v = sym("v", [2, 1]);
x = [r;v];

thrust = sym("thrust_accel", [2,1]); % Thrust over mass
u = thrust;
tf = sym("tf");
p = tf;

rdot = v;
vdot = -mu/sqrt(r(1)^2+r(2)^2)^3*r + u;

xdot = [rdot; vdot] * tf;

% Create equations of motion function for optimizer
matlabFunction(xdot,"File","dynamics_free_tf","Vars", [{t}; {x}; {u}; {p}]);

% Create equations of motion block for Simulink model
%matlabFunctionBlock('EoM_3DoF/SymDynamics3DoF',xdot,'Vars',[x; u; mass; L; I])

% Create Jacobian functions for Kalman filter
%matlabFunction(j_a,"File","3DoF/SymXJacobian3DoF","Vars",[x; u; mass; L; I]);
%matlabFunction(j_b,"File","3DoF/SymUJacobian3DoF","Vars",[x; u; mass; L; I]);