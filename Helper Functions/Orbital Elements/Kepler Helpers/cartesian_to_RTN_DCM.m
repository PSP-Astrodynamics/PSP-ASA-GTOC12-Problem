function C = cartesian_to_RTN_DCM(i,Omega,omega,nu)
    %C = angle2dcm(Omega, i, nu + omega, "ZXZ");
    %C = orbit_DCM(Omega, i, nu + omega);
    C = D313(Omega, i, nu + omega);
end

function [D313] = D313(RAAN,i,f)
D313 = [cos(RAAN)*cos(f)-sin(RAAN)*cos(i)*sin(f), -cos(RAAN)*sin(f)-sin(RAAN)*cos(i)*cos(f), sin(RAAN)*sin(i);...
        sin(RAAN)*cos(f)+cos(RAAN)*cos(i)*sin(f), -sin(RAAN)*sin(f)+cos(RAAN)*cos(i)*cos(f), -cos(RAAN)*sin(i);...
        sin(i)*sin(f)                           , sin(i)*cos(f)                            , cos(i)];
end