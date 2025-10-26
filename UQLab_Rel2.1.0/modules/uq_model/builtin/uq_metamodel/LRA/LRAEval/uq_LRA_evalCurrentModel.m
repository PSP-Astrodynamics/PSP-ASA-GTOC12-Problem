function Y_eval = uq_LRA_evalCurrentModel(P, z, b, l)
% This function evaluates the LRA at the l-th step given the values of the
% univariate polynomials, P_val, and the LRA coefficients, z and b.

% Get sample size and input dimension
N_eval = size(P{1},1);
M = length(P);

% Initialize variables
Y_eval = zeros(N_eval,1);
w = ones(N_eval,l);

% Evaluate LRA
for m = 1:l
    for i = 1:M
         w(:,m) = (P{i}*z{m}(:,i)).*w(:,m);
    end
    
    Y_eval = Y_eval+b(m)*w(:,m);
    
end

