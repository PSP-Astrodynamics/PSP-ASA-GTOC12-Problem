function [f,T,L,U] = pivot(f,z,T,L,U,ee,isU)    
    %Add entering arc to make a cycle and find a leaving arc, an arc on the cycle.
    %Adjust the feasible tree solution "f".
    
    % Copyright (c) 2011-2012 by Hongxun Jiang
    % Matlog Version 2 01-FEB-2012

    n = length(z);
    Tnew = [T;ee];   
    %coder.varsize("T", [97, 1], [1, 0]);
    
    %selecting a leveiving arc "x"
    [x, af, bn] = findBn(Tnew,ee,z, isU);        
    q = find(Tnew == vertex(x(af+1),x(af),n));
    if isempty(q)
        q = find(Tnew == vertex(x(af),x(af+1),n)); 
        U = [U;Tnew(q)]; 
    else
        L = [L;Tnew(q)];       
    end
    T = Tnew(((1:98) ~= q)); 
    
    %adjust the spinning tree
    len = length(x);
    for i=1:len-1
        f(x(i),x(i+1)) = f(x(i),x(i+1)) + bn;       
    end
    
    F = find(f);
    F1 = coVertex(F,n)';
    for i = 1:length(F)
        m = min(f(F(i)),f(F1(i)));
        f(F(i)) = f(F(i)) - m;
        f(F1(i)) = f(F1(i)) - m;
    end
end


