function [L,U,ee,isU] = selArc(L, pi, g, U)
    %Pick a nontree arc having a negative dual slack 
    % ifU, a boolean variable. when ifU = 1, it means arc "ee" selected from U£¬otherwise, ifU = 0.
    
    % Copyright (c) 2011-2012 by Hongxun Jiang
    % Matlog Version 2 01-FEB-2012

    ee = [];
    isU = 0;

    p = potential( L,pi,g);         
    e = find(p<0);                  
    if ~isempty(e)                  
        i = find(e == min(e));
        ee = L(e(i(1)));
        L(e(i(1))) = [];              
    else                            
        p = potential( U,pi,g);     
        e = find(p>0);              
        if ~isempty(e)
            i = find(e == min(e));
            ee = U(e(i(1)));
            U(e(i(1))) = []; 
            isU = 1;
        end
    end
 
end

