function [ cc ] = checkCycle( b )
%CHECKCYCLE returns the set of arcs making a circuit with each other

% Copyright (c) 2011-2012 by Hongxun Jiang
% Matlog Version 2 01-FEB-2012

    n = length(b);
    arcs = find(b);
    
    coArcs = coVertex(arcs,n)';
    
    cc = intersect(arcs,coArcs);
    
end

