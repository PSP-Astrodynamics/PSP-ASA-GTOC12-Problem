function [ p ] = potential( L,pi,g )
%reduced cost of every arc computed by the potential "pi"

    m = length(L);                      
    n = length(g);                   
    
    p = zeros(1,m);    
    for i=1:m
        [col,row] = myDivide(L(i),n);     
        p(i)= g(row,col) - pi(row) + pi(col);  
    end
    
    
end
