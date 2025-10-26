function [ pi ] = pt(T,g)
% This function computes the potentials at all vertexs for the given tree.
% In the computation, Warshall-Floyd Algorithm is used

    n = length(g); 
    t = zeros(n); 
    
    T1 = coVertex(T,n);
    t(T) = g(T);
    t(T1) = -g(T);
    
    W = FastFloyd(t);  
    pi = W(:,n); 
end
                             
