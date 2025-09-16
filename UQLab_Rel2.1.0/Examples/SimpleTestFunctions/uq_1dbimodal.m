function Y = uq_1dbimodal(X,R)
% One-dimensional stochatic simulator with the response distribution being
% bimodal.
% see X. Zhu and B. Sudret (2023). Stochastic polynomial chaos expansions 
% to emulate stochastic simulators. International Journal for Uncertainty 
% Quantification. 13:31-52.


% get the replications
if nargin<2
    R = 1;
end

% get X info
N = size(X,1);

% Define the distribution
mu1 = -2; sig1=0.8;
mu2 = 2; sig2=0.8;
mul1 = 4; mul2 = 4;
p1 = 0.4;
shift =@(x) 4*sin(pi*x).^2;

% indices associated with the first mode
l1 = rand(N,1,R);
ind = l1<p1;

% latent variable to generate samples for each mode
l2 = randn(N,1,R);
x_design = repmat(X,1,1,R);

% get the samples
Y = zeros(N,1,R);
Y(ind) = l2(ind)*sig1  +(mu1+mul1*x_design(ind))+shift(x_design(ind));
Y(~ind) = l2(~ind)*sig2+(mu2-mul2*x_design(~ind))+shift(x_design(~ind));
end

