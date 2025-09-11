function Y = uq_ishigami(X,P)
% UQ_ISHIGAMI is a simple version of the ishigami function.
%
% See also: UQ_EXAMPLE_PCE_01_COEFFICIENTS,
%           UQ_EXAMPLE_MODEL_01_MODELDEFINITION,
%           UQ_EXAMPLE_KRIGING_ISHIGAMI

% processing the parameters
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


% computing the response value
Y(:,1) = sin(X(:,1)) + a*(sin(X(:,2)).^2) + b*(X(:,3).^4).* sin(X(:,1));
