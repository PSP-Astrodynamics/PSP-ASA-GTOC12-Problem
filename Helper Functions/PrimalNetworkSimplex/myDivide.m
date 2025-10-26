function [ x,y ] = myDivide( a, b )

    x = ceil(a/b);         
    y = mod(a,b); 
    
    m = y == 0;
    y(m) = b;
    
end

