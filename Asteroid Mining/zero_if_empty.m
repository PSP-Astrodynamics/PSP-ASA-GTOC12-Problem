function [v] = zero_if_empty(v)
%ZERO_IF_EMPTY Summary of this function goes here
%   Detailed explanation goes here
%v(isempty(v)) = 0;
if isempty(v)
    sz = size(v);
    sz(sz == 0) = 1; 
    v = zeros(sz);
end
end

