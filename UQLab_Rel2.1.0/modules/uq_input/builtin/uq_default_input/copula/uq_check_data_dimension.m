function uq_check_data_dimension(X, M)
% UQ_CHECK_DATA_DIMENSION(X, M)
%     Raises error if the input array X has not exactly M columns. 
%
% INPUT:
% X : array n-by-M
% M : integer
% 
% OUTPUT:
% none

m = size(X, 2);
if size(X, 2) ~= M
    error('Input argument is an array with %d (instead of %d) columns', ...
        m, M);
end
