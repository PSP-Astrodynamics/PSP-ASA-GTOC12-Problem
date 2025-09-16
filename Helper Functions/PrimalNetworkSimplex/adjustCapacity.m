function [ z ] = adjustCapacity( b,f,cc,T )
%do re-adjust the upper bound of each arcs in the spanning tree

% Copyright (c) 2011-2012 by Hongxun Jiang
% Matlog Version 2 01-FEB-2012

    if isempty(cc)                      %no circuit exists
        z = b - f + f.';               
    else
        n = length(b);
        c = intersect(T,cc);
        c = coVertex(c,n);
        b(c) = 0;
        z = b - f + f.';
    end
    
end

