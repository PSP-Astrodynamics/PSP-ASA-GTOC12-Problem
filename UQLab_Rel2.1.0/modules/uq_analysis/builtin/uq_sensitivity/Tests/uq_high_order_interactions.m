function Y = uq_high_order_interactions(X)
% Y = UQ_HIGH_ORDER_INTERACTIONS(X): test function to test sensitivity
%     methods in the presence of high order interactions (up to 4th order)
%
% See also: UQ_TEST_SOBOL_HIGH_ORDER_INTERACTIONS

% Total Sobol' indices are expected for all the factors, plus two high and
% equal values for the interactions X1-X4 and X5-X8 (0.5 each) 

Y = X(:, 1).*X(:, 2).*X(:, 3).*X(:, 4) + X(:, 5).*X(:, 6).*X(:, 7).*X(:, 8);