function [a] = semimajor_from_r_v_mu(r, v, mu)
%SEMIMAJOR_FROM_R_V_MU Summary of this function goes here
%   Detailed explanation goes here

    a = -mu / 2 / (v^2 / 2 - mu / r);
end

