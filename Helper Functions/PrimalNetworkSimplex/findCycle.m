function [ pr] = findCycle( A,ee,isU )
% Find the cycle path due to adding an entering arc "ee" into T.
% If one add an arc to a tree, there arise the unique circuit.
% this function "cy" compurtes this unique circuit for the input data:
% A : adjacency matrix of the graph obtained from the tree by adding new arc
% between two vertices in the tree with an infinite cost.
% i,j : two specified vertices in the tree

% Copyright (c) 2011-2012 by Hongxun Jiang
% Matlog Version 2 01-FEB-2012


    A(ee) = inf;
    A(A==0) = inf;

    [j,i] = myDivide(ee,length(A));

    [P, d] = shortestpath(digraph(A),i,j);
    %[d, P, ~] = graphshortestpath(sparse(A),i,j); %the shortest path, and there is one and only one path
    m = length(P);
    for i = 1:m
        pr(i) = P(m-i+1);
    end
    pr(m+1) = j;

    if isU
        pr = [j P];
    end
    
end