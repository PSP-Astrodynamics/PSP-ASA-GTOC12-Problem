function Y = myFunction(X,P)
%MYFUNCTION computes the Ishigami function.

% processing the parameters
switch nargin
    case 1
        a = 7;
        b = 0.1 ;
    case 2 
        a = P.a;
        b = P.b;
    otherwise    
        error('Number of input arguments not accepted!');
end

% computing the response value
Y(:,1) = sin(X(:,1)) + a*(sin(X(:,2)).^2) + b*(X(:,3).^4).* sin(X(:,1));
