function pass = uq_check_data_in_unit_hypercube(U)
% isTrue = UQ_CHECK_DATA_IN_UNIT_HYPERCUBE(U)
%    Raises error if not all elements in the array U lie in the interval 
%    [0,1]. (Used internally in UQlab for copula-related operations).
%
% INPUT:
% U : array of any size
% 
% OUTPUT:
% isTrue: 1
%     returns 1 if all elements of U lie in the unit hypercube

if any(U(:)<0) || any(U(:)>1)
    error('Not all data points lie within the interval [0,1]')
elseif any(isnan(U(:)))
    error('Some data points are NaNs')
end

pass = 1;
