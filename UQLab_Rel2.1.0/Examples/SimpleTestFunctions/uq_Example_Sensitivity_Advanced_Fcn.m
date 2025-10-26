function Y = uq_Example_Sensitivity_Advanced_Fcn(X)
% UQ_EXAMPLE_SENSITIVITY_ADVANCED_FCN is a function with a 5-dimensional
% input vector mapping to a output scalar.
%
% See also: UQ_EXAMPLE_SENSITIVITY_ADVANCED

Y = 5*X(:, 1).*X(:, 2) + 2*X(:, 3) + 3*X(:, 4) - sin(X(:, 5));