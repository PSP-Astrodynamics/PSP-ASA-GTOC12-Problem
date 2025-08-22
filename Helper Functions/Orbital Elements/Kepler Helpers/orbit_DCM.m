function [C] = orbit_DCM(Omega, i, theta) 
    C = make_R(Omega, 3) * make_R(i, 1) * make_R(theta, 3);
end