%% *_Branin Function_*
%
% Syntax:
% Y = UQ_BRANIN(X)
% Y = UQ_BRANIN(X,P)
%
% The model contains M=2 (independent) random variables (X=[X_1,X_2])
% and 6 scalar parameters of type double (P=[a,b,c,r,s,t]).
%
% Input:
% X     N x M matrix including N samples of M stochastic parameters
% P     vector including parameters
%       by default: a = 1; b = 5.1/(2*pi)^2; c = 5/pi; r = 6; s = 10;
%                   t = 1/(8*pi);
%
% Output/Return:
% Y     column vector of length N including evaluations using branin
%       function
%


%%%
function Y = uq_branin(X,P)


%% Check
%
narginchk(1,2)

assert(size(X,2)==2,'only 2 input variables allowed')


%% Evaluation
%
% $$f(\mathbf{x}) = a(x_2 - bx_1^2 + cx_1 - r)^2 +s(1-t)\cos(x_1) +s$$
%

if nargin==1
    % Constants
    a = 1;
    b = 5.1/(2*pi)^2;
    c = 5/pi;
    r = 6;
    s = 10;
    t = 1/(8*pi);
    
    Y = a*(X(:,2) - b*X(:,1).^2 + c*X(:,1) - r).^2 + s*(1-t)*cos(X(:,1)) + s;
end


if nargin==2
    Y = P(1)*(X(:,2) - P(2)*X(:,1).^2 + P(3)*X(:,1) - P(4)).^2 + P(5)*(1-P(6))*cos(X(:,1)) + P(5);
end


end