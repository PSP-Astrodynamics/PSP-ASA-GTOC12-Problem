function isSymmetric = uq_pair_copula_is_symmetric(family)
% isSymmetric = uq_pair_copula_is_symmetric(family)
%     Returns 1 if the specified pair copula family is symmetric wrt the 
%     main diagonal (that is, c(u,v)=c(v,u) for a copula with density c).
%     Returns 0 otherwise.

family = uq_copula_stdname(family);
uq_check_pair_copula_family_supported(family);

SymmetricFamilies = {'Independent', 'Gaussian', 't', 'Gumbel', ...
    'Frank', 'Clayton'};
isSymmetric = any(strcmpi(family, SymmetricFamilies));
