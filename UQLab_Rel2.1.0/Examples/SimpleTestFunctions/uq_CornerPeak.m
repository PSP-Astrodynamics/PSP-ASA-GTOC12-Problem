function Y = uq_CornerPeak(X,options)
% function Y = uq_CornerPeak(X)
% Computes the corner peak function defined as
%       Y_i = (1 + sum_{k=1}^{d} (c_{i,k} xi_k))^(-(d+1))
%
% Model has d input parameters defined as: 
%       X = [xi_1, ...., xi_d]
%
% The coefficients of the corner peak function can be calculated using 
% three different equations
%       c_{1,k} = (k-1/2)/d
%       c_{2,k} = 1/k^2
%       c_{3,k} = exp(k*log(10^-8)/d)
% The coefficients are normalized to have
%       sum_{k=1}^{d} c_{i,k} = 0.25

% Chose coefficient type to be computed and TargetSumg
Type = 1;           % Set coefficient type 1 to default
TargetSum = 0.25;     % Set TargetSum to 1 for default

% Check if type option has been passed into the function
if exist('options','var')
    % Check if coefficient type has been chose
    if isfield(options,'type');
        Type = options.Type; 
    end
    
    % Check if TargetSum of coefficients has been chosen
    if isfield(options,'TargetSum'); 
        TargetSum = options.TargetSum; 
    end
end

% Matrix X should be of size [n,d], so we can first retrieve the
% dimension of the problem
[n,d] = size(X);

% Compute the coefficients based on the option chosen
c = zeros(1,d);     % Initialize coefficient array
for k=1:d
    switch Type
        case 1
            c(k) = (k-1/2)/d;
        case 2
            c(k) = 1/k^2; 
        case 3
            c(k) = exp(k*log(10^-8)/d); 
    end
end

% Normalize sum of coefficients to 0.25
csum = sum(c); 
cn = TargetSum*c/csum;   % sum cn = targetsum
C = ones(n,1)*cn;        % create matrix where each row is the 
                         % coefficient vector

% Automatic implementation of corner peak function
Y = (1 + sum(C.*X,2)).^(-(d+1));


