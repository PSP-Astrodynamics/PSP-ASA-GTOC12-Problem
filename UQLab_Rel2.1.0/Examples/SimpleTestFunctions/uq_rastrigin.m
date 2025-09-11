%% *_Modified Rastrigin Function_*
%
% Syntax:
% Y = UQ_RASTRIGIN(X)
%
% The model contains M=2 (independent) random variables (X=[X_1,X_2])
%
% Input:
% X     N x M matrix including N samples of M stochastic parameters
%
% Output/Return:
% Y     column vector of length N including evaluations using modified
%       rastrigin function
%
% See also: UQ_EXAMPLE_PCE_RASTRIGIN_REGRESSION

%%%
function Y = uq_rastrigin(X)


%% Check
%
narginchk(1,1)

assert(size(X,2)==2,'only 2 input variables allowed')


%% Evaluation
%
% $$f(\mathbf{x}) = 10 - \sum_{i=1}^2 \big( X_i^2 - 5 \cos(2 \pi X_i)
% \big)$$
%

Y = 10 - sum(X.^2 - 5*cos(2*pi*X), 2);


end