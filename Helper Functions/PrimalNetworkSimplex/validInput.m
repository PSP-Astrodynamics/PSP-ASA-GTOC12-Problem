function [ isValid ] = validInput( A,D,G )
% This function provides the inputting validation of the adjacency matrixA, 
% the demand vector D and the arc cost matrix G.
% A and G must be two full square matrix. 
% The number of rows/columns of A or G is equal to the number of nodes of D.
% Sum of the D(i) for all vertices 1,бн,N must be 0.

%INPUT:
% "A" is an N by N matrix whose entries A(i,j) denote the capacities of the arc ij. Assume A(i,j) are nonnegative integers. 
% "D" is a N-dimensional vector whose integer entries D(i) denote the demand function of the vertex i: if d(i)>0 vertex i is called a demand vertex and if d(i)<0, it is called a supply vertex. 
% "G" is an N by N matrix whose entries G(i,j) denote the costs of the arc ij. Assume g(i,j) are nonnegative.

%INPUT:
% "isValid", a boolean variable 

% Copyright (c) 2011-2012 by Hongxun Jiang
% Matlog Version 2 01-FEB-2012

    isValid = 0;

    n1 = size(A,1);     n2 = size(A,2); 
    if n1~=n2
        return;
    end
    
    m1 = size(G,1);    m2 = size(G,2); 
    if m1~=m2     
        return;        
    end
    
    if n1~=m1   
        return;        
    end
    
    n = length(D);
    if n1~=n   
        return;        
    end
    
    if sum(D)  
        return;  
    end
    
    isValid = 1;
end

