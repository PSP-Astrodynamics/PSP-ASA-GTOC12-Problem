%% *_Hat Function_*
%
% Syntax:
% Y = UQ_HAT(X)
% Y = UQ_HAT(X,P)
%
% The model contains M=2 (independent) random variables (X=[X_1,X_2])
% and 3 scalar parameters of type double (P=[a, b, c]).
%
% Input:
% X     N x M matrix including N samples of M stochastic parameters
% P     vector including parameters
%       by default: a = 4; b = 8; c = 20;
%
% Output/Return:
% Y     column vector of length N including evaluations using hat function
%
% See also: UQ_EXAMPLE_RELIABILITY_02_HAT


%%
function Y = uq_hat(X,P)


%% Check
narginchk(1,2)

[~,col] = size(X);
assert(col==2,'only 2 input variables allowed')


%% Evaluation
%
% $$Y = c - (X_1-X_2)^2 - b\cdot (X_1+X_2-a)^3$$
%

if nargin==1
    % Constants
    a = 4;       
    b = 8;            
    c = 20;        
    
    Y = c - (X(:,1)-X(:,2)).^2 - b*(X(:,1)+X(:,2)-a).^3;
end


if nargin==2
    Y = P(3) - (X(:,1)-X(:,2)).^2 - P(2)*(X(:,1)+X(:,2)-P(1)).^3;
end


end