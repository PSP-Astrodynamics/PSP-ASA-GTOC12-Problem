function [x_cartesian] = orb2cartOrig(a,ecc,inc,RAAN,argp,f,mu)
% orb2cart converts Keplerian orbital elements into Cartesian position
% and velocity. Distances will be provided in km, velocities provided in
% km/s, and angles will be given in degrees. This function is only
% valid for circular and elliptical orbits.

% Constants
p = a*(1-ecc^2);
hmag = sqrt(p*mu);
rmag = (hmag^2/mu)/(1+ecc*cos(f));
rVec = [rmag*cos(f), rmag*sin(f), 0];
vVec = [-(mu/hmag)*sin(f), (mu/hmag)*(ecc+cos(f)), 0];
DCM313 = D313(RAAN,inc,argp);
r = DCM313 * rVec';
v = DCM313 * vVec';
x = r(1);
y = r(2);
z = r(3);
vx = v(1);
vy = v(2);
vz = v(3);

x_cartesian = [x; y; z; vx; vy; vz];
end

function [D313] = D313(RAAN,i,f)
D313 = [cos(RAAN)*cos(f)-sin(RAAN)*cos(i)*sin(f), -cos(RAAN)*sin(f)-sin(RAAN)*cos(i)*cos(f), sin(RAAN)*sin(i);...
        sin(RAAN)*cos(f)+cos(RAAN)*cos(i)*sin(f), -sin(RAAN)*sin(f)+cos(RAAN)*cos(i)*cos(f), -cos(RAAN)*sin(i);...
        sin(i)*sin(f)                           , sin(i)*cos(f)                            , cos(i)];
end