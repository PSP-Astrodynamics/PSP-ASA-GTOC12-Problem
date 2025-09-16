function U = uq_NatafTransform(X, marginals, copula)
% U = UQ_NATAFTRANSFORM(X, Marginals, Copula):
%     performs (Generalised) Nataf Transformation of samples (X) 
%     from the physical defined by the specified marginals and elliptical 
%     copula (t or Gaussian) to the standard normal space (U)
%
%     References:
%       Lebrun, R. and Dutfoy (2009), A., A generalization of the Nataf 
%       transformation to distributions with elliptical copula, 
%       Prob. Eng. Mech. 24(2), 172-178
% INPUT: 
% X : array n-by-M
%     sample set of n M-dimensional observations 
% Marginals : struct 
%     Marginal distributions of the samples in X
% Copula : struct
%     Copula of the samples in X
%
% OUTPUT:
% U : array n-by-M
%     Transformed observations in the standard normal space
%
% See also: UQ_INVNATAFTRANSFORM

%% Get the non-constant components of the random vector
% find the indices of the non-constant components
Types = {marginals(:).Type};
indConst = strcmpi(Types, 'constant'); 
indNonConst = ~indConst ;
% store non-constant components in X
XX = X(:,indNonConst) ;

% NOTE: 
% In the algorithm that follows the symbols from (Lebrun and Dutfoy, 2009)
% are mostly adopted

%% Do isoprobabilistic transformation from X to V
% V denotes the samples in the standard elliptical space where covariance is still existent
switch lower(copula.Type)
    case 'gaussian'
        [vMarginals(1:length(marginals(indNonConst))).Type] = deal('gaussian') ;
        [vMarginals(1:length(marginals(indNonConst))).Parameters] = deal([0 1]) ;
        V = uq_IsopTransform(XX, marginals(indNonConst), vMarginals);
    case 'student'
        [vMarginals(1:length(marginals(indNonConst))).Type] = deal('student') ;
        [vMarginals(1:length(marginals(indNonConst))).Parameters] = deal(1) ;
        V = uq_IsopTransform(XX, marginals(indNonConst), vMarginals);
    otherwise
        error('Error: non-elliptical or unknown type of elliptical copula!')
        return;
end
%% Perform step 3: mapping from V to U
% if the Cholesky decomposition of the correlation matrix already exists
% use it, otherwise calculate it here (and store it)
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

% Replace infs in V with +/- realmax to avoid nans when multiplying with
% choleski factor L
V_is_inf = find(isinf(V));
sign_inf = sign(V(V_is_inf));
V(V_is_inf) = sign_inf * realmax;

% Produce U (of non - constant marginals)
U = zeros(size(X)) ;
U(:,indNonConst) = V / L;
U(V_is_inf) = sign_inf * inf;

% the U's of constant marginals (if any) are zero
