function Y = uq_shortcol(X)
% Y = UQ_SHORTCOL(X) returns the value of the limit state function Y of the
% strength of a short, square (5x15) steel column subjected to an axial
% load and a bending moment. The problem is described by 3 variables given
% in X = [Y, M, P] 

%
% Y 	-	yield stress    (MPa)
% M 	-	bending moment  (Nmm)
% P 	-	axial force     (N)
%
% For more info, see: http://www.sfu.ca/~ssurjano/shortcol.html
% 
% See also: UQ_EXAMPLE_SENSITIVITY_05_ANCOVAIndices,

Y = X(:, 1);
M = X(:, 2);
P = X(:, 3);

% define cross-section wisth and depth
b = 5;
h = 15;

% Calculate the single terms:
term1 = -4*M ./ (b.*(h.^2).*Y);
term2 = -(P.^2) ./ ((b.^2).*(h.^2).*(Y.^2));


Y = 1 + term1 + term2;