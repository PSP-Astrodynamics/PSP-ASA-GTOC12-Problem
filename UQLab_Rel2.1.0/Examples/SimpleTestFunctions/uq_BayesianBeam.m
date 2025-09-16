function V = uq_BayesianBeam(X)
% UQ_SIMPLYSUPPORTEDBEAM computes the midspan and quarter point deflection of a simply 
% supported beam under uniform loading
%
%   Model with five input parameters  X= [b h L E p]
%         b:   beam width
%         h:   beam height
%         L:   beam span
%         E:   Young's modulus
%         p:   uniform load
%
%   Output:  V(:,1) =   (5/32)*pL^4/(E*b*h^3)
%            V(:,2) = (57/512)*pL^4/(E*b*h^3)
% 
% See also: 

% Vectorized implementation
V = [ (57/512)*(X(:, 5).*X(:, 3).^4)./(X(:, 4).*X(:, 1).*X(:, 2).^3),... % L/4
        (5/32)*(X(:, 5).*X(:, 3).^4)./(X(:, 4).*X(:, 1).*X(:, 2).^3)];   % L/2
