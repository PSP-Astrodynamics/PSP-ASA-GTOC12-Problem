function Y = uq_GBM(X,R)
%% Simulate the value of a geometric Bronian motion at time 1
% $$dS_t(\mathbf{x}) = x_1 S_t + x_2 dW_t$$
% with the boundary condition $S_0(\mathbf{x}) = 1$.
% The model parameters are given in X, and $Y = S_1(\mathbf{x})$
% According to Ito's calculus, $Y_\mathbf{x}} follows a lognormal 
% distribution 
% $$Y_\mathbf{x} \sim \mathcal{LN}(x_1-x_2^2/2,x_2) $$
% As a result, we do not simulate the whole GBM but sample directly
% the reference response distribution

% If only one variable is given, we set R=1
if nargin==1
    R = 1;
end

% Evaluate the distribution parameters
mu = X(:,1) - X(:,2).^2/2;
zeta = X(:,2);
% Get the number of samples
N = size(X,1);
% Sample a standard normal distribtion
xi = randn(N,1,R);
% Perform the transform to get the samples from the desired lognormal
% distribution
ynorm = bsxfun(@times,zeta,xi);
ynorm = bsxfun(@plus,mu,ynorm);
Y = exp(ynorm);
end