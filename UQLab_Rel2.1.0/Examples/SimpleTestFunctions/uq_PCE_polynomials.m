function Y = uq_PCE_polynomials(X)

%% Function built using orthonormal polynomials according to specification

% Define input variable type 
%   'u':    Uniform
%   'g':    Normal / Gaussian
type = ['u','g','g','u','u','g','u'];

% Define polynomial degree for univariate polynomials
alphas = [1,0,2,0,1,5,1;...     % 10
          0,7,1,0,0,0,2;...     % 10
          1,1,1,1,1,1,1;...     % 7
          0,0,0,1,0,0,0;...     % 1
          3,0,0,5,0,2,0;...     % 10
          0,0,10,0,0,0,0];      % 10

% Define coefficients for multivariate polynomials
coeff = [100.01,23.67,98.234,...
        0.1,8.91,0.001];

%% Build polynomials
[n,~] = size(X);
Y = zeros(n,1);

% Iterative procedure to build polynomials
for i=1:numel(coeff)
    % Initialize multivariate polynomial
    Y_help = ones(n,1)*coeff(i);
    
    for j=1:numel(type)
        % Retrieve polynomial type1
        pol = type(j);
        switch pol
            case 'u'
                Y_help = Y_help.*uq_eval_legendre(alphas(i,j),X(:,j),1);
            case 'g'
                Y_help = Y_help.*uq_eval_hermite(alphas(i,j),X(:,j),1);
        end
    end
    
    % Add new multivariate polynomial to function
    Y = Y + Y_help;
end

