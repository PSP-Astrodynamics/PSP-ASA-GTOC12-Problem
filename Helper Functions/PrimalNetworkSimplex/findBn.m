function [ x, af, bn] = findBn( T,ee,z,isU )
    % find a leaving arc "x", 
    % Leaving arc is an arc on the cycle, pointing in the opposite direction to the entering arc "ee", 
    % and of all such arcs, it is the one with the smallest primal flow "bn".
    % "af" is the node from which the arc "x" goes to anohter node.
    
    % Copyright (c) 2011-2012 by Hongxun Jiang
    % Matlog Version 2 01-FEB-2012
    
    
    n = length(z);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    %An  undirected path is  defined  in the  same way  as  a directed  path
    %except  that the orientation  of the  arcs  along  the path is inconsequential
    A = zeros(n);
    T1 = coVertex(T,n);
    A(T) = 1;    
    A(T1) = 1;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %find the cycle path due to adding an entering arc "ee" into T.
    [x] = findCycle(A, ee, isU);    

    len = length(x);
    for i=1:len-1                                    
        y(i) = z(x(i),x(i+1));     
    end

    bn = min(y);                 %bottleNeck
    af = find(y == bn);

    if length(af) > 1     
        BN = FastFloyd(A);
        
        least = BN(n,:);                      
        X = least(x);                          
        i = find(X==min(X),1);    
        x(len) = [];			                 
        x = circshift(x,[1,-i+1]);             
        x(len) = x(1);                          
        
        for i=1:len-1                                    
            y(i) = z(x(i),x(i+1));
        end 
       
        aff = find(y==bn); 
        af = max(aff);
    end
    
end

