function Y = uq_ishigami_various_outputs(X, P)
% UQ_ISHIGAMI_VARIOUS_OUTPUTS is a modified version of the Ishigami 
% function, that produces two outputs, for testing purposes.
% The first output is the usual Ishigami response, the second is 100*X1 and
% the third is again the Ishigami function. This way, consistency and
% correctness of the methods can be checked.
%
% See also: UQ_TEST_SENSITIVITY_ISHIGAMI_OUTPUTS,
%           UQ_EXAMPLE_KRIGING_ISHIGAMI_MULTIPLEOUTPUTS


switch nargin
    case 1
        a = 7;
        b = 0.1 ;
    case 2 
        a = P(1);
        b = P(2);
    otherwise    
        error('Number of input arguments not accepted!');
end

% Ishigami:
Y(:, 1) = sin(X(:, 1)) + a*(sin(X(:, 2)).^2) + b*(X(:, 3).^4).* sin(X(:, 1));

% 100*X1^3
Y(:, 2) = 100*X(:, 1).^3;

% Ishigami:
Y(:, 3) = Y(:, 1);