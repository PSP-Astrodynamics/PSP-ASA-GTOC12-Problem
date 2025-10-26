function M = uq_de2bi(x, l)
% M = uq_de2bi(x, l)
%     Given an array x of non-negative integers, transforms the array into
%     a matrix M by converting each element of the array to base 2 vector
%     (row of M). The lower bit is at the right. 
%     Optionally, specify the wanted number l of bits for the representation.
%
% INPUT:
% x : scalar or one-dimensional array of non-negative integers
%   Decimal value(s) to be converted to base 2 array
% l : positive integer or 'auto', optional
%   second dimension of the output M (number of digits used to express each 
%   output value). Default: 'auto', i.e. minimum number needed for conversion
%
% OUTPUT:
% M : array n by l
%   matrix of integers in x converted to base 2

% base of the conversion
b = 2;

assert(all(x-floor(x) == 0), 'input argument x must contain integers only')
assert(sum(size(x) > 1) == 1, 'x must be one-dimensional')

x = x(:);
Max = max(x);
Min = min(x);
n = length(x);
assert(Min >=0, 'x must contain non-negative integers only. Negative values found')

% Determine minimum number of bits required
if Max > 0 			
   l_min = ceil(log(Max)/log(b));
else 						
   l_min = 1;
end

% Set l, the number of bits used for the conversion
if nargin < 2, 
    l=l_min; 
elseif l < l_min
    error('l=%d is too small, at least l=%d bits needed to represent %d in base %d', ...
        l, l_min, Max, b)
end
    

if b==2 % Vectorized conversion for b=2 case
    [~,e]=log2(Max); % How many digits do we need to represent the numbers?
    M = rem(floor(x*pow2(1-max(l,e):0)), b);
else
    error('Only base b=2 currently supported')
end;



