function [DCM_array] = RTN_to_ECI_array(r, v)
%RTN_TO_ECI_ARRAY Summary of this function goes here
%   Detailed explanation goes here
N = size(r, 2);
DCM_array = zeros(3, 3, N);

for n = 1 : N
    DCM_array(:, :, n) = RTN_to_ECI(r(:, n), v(:, n));
end

end