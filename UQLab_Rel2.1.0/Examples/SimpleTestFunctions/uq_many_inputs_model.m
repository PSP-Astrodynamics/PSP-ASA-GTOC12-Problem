function Y = uq_many_inputs_model(X)
% Y = UQ_MANY_INPUTS_MODEL(X) is a simple function that returns a non-linear
% combination of the input parameters. Useful to test  sensitivity
% analysis, as it should show a monotonically increasing sensitivity trend.
% 
% The input parameter X can have any number of components > 55, while Y will be
% a vector of scalars.
%
% See also: UQ_EXAMPLE_SENSITIVITY_03_HIGHDIMENSIONALSOBOL,
%           UQ_EXAMPLE_PCE_MANY_INPUTS

if size(X,2) < 5
    error('uq_many_inputs is defined for inputs with more than 5 components');
end

X = transpose(X);

% add some increasing weight to the various components of X
L = repmat(transpose(1:size(X,1)), 1, size(X,2));

% create an array that is a non-linear sum of the elements of the original
% X input vector
Y = 3 + L.*X.^3 + 1/3*L.*log(X.^2 + X.^4) -5*L.*X ;

% squeeze it to a single row, and add extra sensitivity terms for
% X51
% X1X2^2
% X50X54^2
% X3X5
% X2X4

Y = mean(Y,1) + X(1,:).*X(2,:).^2 - X(5,:).*X(3,:) + X(2,:).*X(4,:) + X(51,:) + X(50,:).*X(54,:).^2;
Y = transpose(Y);