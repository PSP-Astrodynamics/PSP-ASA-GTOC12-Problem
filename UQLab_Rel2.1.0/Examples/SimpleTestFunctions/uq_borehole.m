function Y = uq_borehole(X)
% Y = uq_borehole(X) returns the value of the water flow Y through a
% borehole, described by 8 variables given in X = [rw, r, Tu, Hu, Tl, Hl, L, Kw]
%
% rw 	-	radius of borehole (m)
% r 	-	radius of influence (m)
% Tu 	-	transmissivity of upper aquifer (m^2/yr)
% Hu 	-	potentiometric head of upper aquifer (m)
% Tl 	-	transmissivity of lower aquifer (m^2/yr)
% Hl 	-	potentiometric head of lower aquifer (m)
% L 	-	length of borehole (m)
% Kw 	-	hydraulic conductivity of borehole (m/yr)
%
% For more info, see: http://www.sfu.ca/~ssurjano/borehole.html
% 
% See also: UQ_EXAMPLE_SENSITIVITY_01_BOREHOLE_MODEL,
%           UQ_EXAMPLE_SENSITIVITY_02_SOBOLINDICES

rw = X(:, 1);
r  = X(:, 2);
Tu = X(:, 3);
Hu = X(:, 4);
Tl = X(:, 5);
Hl = X(:, 6);
L  = X(:, 7);
Kw = X(:, 8);

% Precalculate the logarithm:
Logrrw = log(r./rw);

Numerator = 2*pi*Tu.*(Hu - Hl);
Denominator = Logrrw.*(1 + (2*L.*Tu)./(Logrrw.*rw.^2.*Kw) + Tu./Tl);

Y = Numerator./Denominator;