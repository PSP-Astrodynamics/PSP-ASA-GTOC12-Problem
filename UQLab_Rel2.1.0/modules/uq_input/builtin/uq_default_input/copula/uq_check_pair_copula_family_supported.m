function uq_check_pair_copula_family_supported(family)
% UQ_CHECK_PAIR_COPULA_FAMILY_SUPPORTED(family)
%     Raises error if the specified family of pair copulas is currently
%     supported in UQlab.
%
% INPUT:
% family : char (copula name) or integer (copula id).
%
% OUTPUT: 
% none
%
% SEE ALSO: uq_SupportedPairCopulas

Supported = uq_SupportedPairCopulas; 
Supported = Supported(:,2);    
if not(any(strcmpi(uq_copula_stdname(family), Supported)))
    error('Pair copula "%s" unknown or not supported yet', family)
end
