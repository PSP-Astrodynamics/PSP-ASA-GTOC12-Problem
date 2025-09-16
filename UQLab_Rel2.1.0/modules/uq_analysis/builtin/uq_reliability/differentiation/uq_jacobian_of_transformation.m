function J = uq_jacobian_of_transformation(X, U, Marginals, Copula, Options)
% J = UQ_JACOBIAN_OF_TRANSFORMATION (X,U,Marginals, Copula, Options):
%     computes the Jacobian matrix for a given point X and its transformed 
%     point U in the standard normal space, with forward finite differences.
%     
% See also: UQ_FORM, UQ_GENERALISOPTRANSFORM

% Dimension
M = length(Marginals); 

ConstIdx = uq_find_constant_marginals(Marginals);
nonConstIdx = uq_find_nonconstant_marginals(Marginals);

% Define marginals and copula of U: indep copula, marginals of U are gaussian 
% for non-constant marginals of X, constant otherwise
StandardMarginals(nonConstIdx) = uq_StdNormalMarginals(length(nonConstIdx));

if ~isempty(ConstIdx)
    Constants = zeros(1, length(ConstIdx));
    StandardMarginals(ConstIdx) = uq_ConstantMarginals(Constants);
end

StandardCopula = uq_IndepCopula(M);

% Compute the Jacobian with finite differences
h = Options.Gradient.h;
H = transpose(eye(M)*h);
MovedU = bsxfun(@plus, U, H);
MovedX = uq_GeneralIsopTransform(MovedU, StandardMarginals, StandardCopula, Marginals, Copula);

% Consider the transformed point as the output of a vector valued function:
MovedX = MovedX';

% Prepare a matrix that substracts the points in the original coordinates:
StaticX = repmat(X', 1, M);

% At the end we do:
% (h(i) is a vector with all zeros and h in the i-th position)
%
%         [ f_1(U + h(1)) - f_1(U), ... , f_1(U + h(M)) - f_1(U)]
% J = 1/h*[      ...                                   ...      ]
%         [ f_M(U + h(1)) - f_M(U), ... , f_M(U + h(M)) - f_M(U)]
%
J = (MovedX - StaticX)/h;
