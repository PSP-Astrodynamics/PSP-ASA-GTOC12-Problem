function X = uq_invNatafTransform( Uin, marginals, copula )
% X = UQ_INVNATAFTRANSFORM(Uin, marginals, copula):
%     performs Inverse (Generalized) Nataf Transformation of samples (U) 
%     from the standard normal space to physical space (X)
%
% References:
%
%   Lebrun, R. and Dutfoy (2009), A., A generalization of the Nataf 
%   transformation to distributions with elliptical copula, 
%   Prob. Eng. Mech. 24(2), 172-178
%
% See also: UQ_NATAFTRANSFORM

X = zeros(size(Uin) ) ;

%% Get the non-constant components of the random vector
% find the indices of the non-constant components
Types = {marginals(:).Type};

% store non-constant components in U, and substitute infinite values with
% largest positive/negative values accepted by Matlab
indConst = strcmpi(Types, 'constant'); 
indNonConst = ~indConst ;
U = Uin(:,indNonConst) ;
U_is_inf = find(isinf(U));
sign_inf = sign(U(U_is_inf));
U(U_is_inf) = sign_inf * realmax;

% NOTE: 
% In the algorithm that follows the symbols from (Lebrun and Dutfoy, 2009)
% are mostly adopted

%% Transform U (standard normal space) to V (Standard Elliptical space with covariance)
% if the Cholesky decomposition of the correlation matrix already exists
% use it otherwise calculate it here (and store it)
if isfield(copula,'cholR') && ~isempty(copula.cholR)
    L = copula.cholR ;
else
    try
        L = chol(copula.Parameters(indNonConst,indNonConst));
        copula.cholR = L;
    catch
        error('Error: The copula correlation matrix is not positive definite or incorrectly defined!')
    end
end
V = U * L;
V(U_is_inf) = sign_inf * inf;

%% Do isoprobabilistic transformation from V to X
switch lower(copula.Type)
    case 'gaussian'
        if sum(indNonConst)
            [vMarginals(1:length(marginals(indNonConst))).Type] = deal('gaussian') ;
            [vMarginals(1:length(marginals(indNonConst))).Parameters] = deal([0 1]) ;

            X(:,indNonConst) = uq_IsopTransform(V, vMarginals, marginals(indNonConst));
        end
    case 'student'
        [vMarginals(1:length(marginals(indNonConst))).Type] = deal('student') ;
        [vMarginals(1:length(marginals(indNonConst))).Parameters] = deal(1) ;

        X(:,indNonConst) = uq_IsopTransform(V, vMarginals, marginals(indNonConst));
    otherwise
        error('Unknown type of elliptical copula')
end

%% Return the values of the constant marginals (if any)
values = zeros(1,sum(indConst)) ;
%get the constant marginals
constMarginals = marginals(indConst);
%get the constant value of each constant marginal 
for ii = 1:sum(indConst)
    values(1,ii) = constMarginals(ii).Parameters(1);
end
%replicate the value of each constant marginal N = size(X,1) times, that is
%the number of samples
X(:,indConst) = repmat(values, size(X,1), 1) ;

