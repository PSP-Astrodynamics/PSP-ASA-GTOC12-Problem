function [ b, c, M, f, pi] = auxiNet( A,G,D )
%   Set up an auxilliary network by adding a new node into the original network, 
%   Label this new node "n+1" as special. For every other node i,
%       if i is a supply node, draw an arc from i to *, unless such an arc already exists
%       if i is a demand node, draw an arc from * to i, unless such an arc already exists
%       Define costs for every new arc is larger than the largest one of the costs of all original arcs.

%   The auxilliary network has an obvious feasible tree solution
%   that can be used to initiate the network simplex algorithm.

% INPUT:
% The adjacency matrix "A", the demand vector "D" and the arc cost matrix "G", of the original network.

% OUTPUT:
% The adjacency matrix "b" and the arc cost matrix "c", of the auxilliary network.
% M is the largest cost of all arcs in the auxilliary network.
% f, an obvious feasible tree solution of the auxilliary network. 
% pi, Simplex multiplier

% Copyright (c) 2011-2012 by Hongxun Jiang
% Matlog Version 2 01-FEB-2012


    n = size(A,1);    
    N = n + 1;
    M = 1 + N * max(max(G));  %set up a largest cost

    %creat an auxilliary network by adding a new node into the original network 
    b = zeros(N);
    c = zeros(N);
    b(1:n,1:n) = A;         
    c(1:n,1:n) = G;         
    D = [D 0]; 
       
    %Compute Node Potentials
    pi=zeros(1,N);
    for i = 1:n
        if D(i)>0                 %demand node                            
            b(N,i) = D(i)+1;      
            c(N,i) = M;                          
            pi(i) = -M;           
        else                      %supply node
            b(i,N) = -D(i)+1;     
            c(i,N) = M;                              
            pi(i) = M;                   
        end
    end
    
    %a basic feasible tree solution
    f = b;  
    f(1:n,1:n) = zeros(n);    
    m = find(f);
    f(m) = f(m) - 1;
    
end

