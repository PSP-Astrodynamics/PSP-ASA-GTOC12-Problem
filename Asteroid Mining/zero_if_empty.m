function [v] = zero_if_empty(v)
%ZERO_IF_EMPTY Summary of this function goes here
%   Detailed explanation goes here
v(isempty(v)) = 0;
end

