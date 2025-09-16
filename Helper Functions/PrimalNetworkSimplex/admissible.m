function [ r ] = admissible( f )
% This function returns the minimum cost flow for the original network if there is no flow on
% the additional arcs in the flow of the new network computed  by the fuction simplex, and else return 0

% Copyright (c) 2011-2012 by Hongxun Jiang
% Matlog Version 2 01-FEB-2012


    n = length(f);
    
    c =  max([f(n,:),f(:,n)']);
    
    if c == 0 
        r = f(1:n-1,1:n-1);        
    else                    
        r = 0;
    end