function [linearized_constraint] = linearize_constraint(constraint, nx, nu, np, var_type, var_ind)
%LINEARIZE_CONSTRAINT Summary of this function goes here
%   Detailed explanation goes here

t_sym = sym("t");
x_sym = sym("x", [nx, 1]);
u_sym = sym("u", [nu, 1]);
p_sym = sym("p", [np, 1]);

if strcmp(var_type, "x")
    constraint_jacobian = matlabFunction(jacobian(constraint(t_sym, x_sym, u_sym, p_sym), x_sym(var_ind)),"Vars", [{t_sym}; {x_sym}; {u_sym}; {p_sym}]);
    linearized_constraint = @(t, x, u, p, x_ref, u_ref, p_ref, k) constraint(t, x_ref, u, p) + constraint_jacobian(t, x_ref, u_ref, p_ref) * (x(var_ind) - x_ref(var_ind));
elseif strcmp(var_type, "u")
    constraint_jacobian = matlabFunction(jacobian(constraint(t_sym, x_sym, u_sym, p_sym), u_sym(var_ind)),"Vars", [{t_sym}; {x_sym}; {u_sym}; {p_sym}]);
    linearized_constraint = @(t, x, u, p, x_ref, u_ref, p_ref, k) constraint(t, x, u_ref, p) + constraint_jacobian(t, x_ref, u_ref, p_ref) * (u(var_ind) - u_ref(var_ind));
elseif strcmp(var_type, "p")
    constraint_jacobian = matlabFunction(jacobian(constraint(t_sym, x_sym, u_sym, p_sym), p_sym(var_ind)),"Vars", [{t_sym}; {x_sym}; {u_sym}; {p_sym}]);
    linearized_constraint = @(t, x, u, p, x_ref, u_ref, p_ref, k) constraint(t, x, u, p_ref) + constraint_jacobian(t, x_ref, u_ref, p_ref) * (p(var_ind) - p_ref(var_ind));
end
end

