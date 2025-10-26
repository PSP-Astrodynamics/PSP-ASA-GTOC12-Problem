function Y = uq_Example_Simple_SR_fcn(X)
% UQ_EXAMPLE_SIMPLE_SR_FCN is a simple function where
% Y = 2*X2 - X1^2

Y = 2*X(:, 2) - X(:, 1).^2;