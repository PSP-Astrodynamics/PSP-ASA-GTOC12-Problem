function uq_check_copula_type_supported(type)
% uq_check_copula_type_supported(type)
%     Checks that the given type (char) is a supported copula type

type = lower(uq_copula_stdname(type));
SupportedTypes = {'auto', 'independent', 'pair', 'gaussian', 'cvine', 'dvine'};

if ~any(strcmpi(type, SupportedTypes))
    error('Copula of type %s unknown or not supported yet', type)
end
