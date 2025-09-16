function [ y ] = vertex( i,j,n )
% VERTEX returns a set of arcs, which be from vertex set i to vertex set j,
% respectively

    y = i + n*(j-1);

