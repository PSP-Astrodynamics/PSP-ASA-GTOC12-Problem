function norms = uq_q_norm(V,q)
% NORMS = UQ_Q_NORM(V) calculates the Q-norm of a set of input row vectors 
% in V

nvectors = size(V,1);
norms = zeros(nvectors,1);

for i = 1:nvectors
    norms(i) = norm(V(i,:), q);
end
