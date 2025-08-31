function [DCM] = RTN_to_ECI(r, v)
%RTN_TO_ECI Summary of this function goes here
%   Detailed explanation goes here

R_hat = r / norm(r);
N_hat = cross(r, v) / norm(cross(r, v));
T_hat = cross(N_hat, R_hat);

DCM = [R_hat, T_hat, N_hat];

end