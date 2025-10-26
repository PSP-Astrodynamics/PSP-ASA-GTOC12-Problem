function Y = uq_Example_General_Reliability_Fcn(X)
% UQ_EXAMPLE_GENERAL_RELIABILTIY_FCN solves the simple reliability problem:
% Y = X1^2 - 2*X2

Y = X(:, 1).^2 - 2*X(:, 2);