function uq_check_copula_is_vine(Copula)
% UQ_CHECK_COPULA_IS_VINE(Copula)
%     Checks that the input argument is a structure with all fields needed
%     to define a vine copula. Raises an error otherwise.
%
% INPUT:
% Copula : struct
%     A structure describing a pair copula (see uq_PairCopula)
%
% OUTPUT:
% none

if not(isfield(Copula, 'Type'))
    error('Field Copula.Type missing')
elseif ~any(strcmpi(Copula.Type, {'CVine', 'DVine'}))
    error('Copula.Type must be CVine or DVine')
elseif not(isfield(Copula, 'Structure'))
    error('Field Copula.Structure missing')
elseif not(isfield(Copula, 'Families'))
    error('Field Copula.Families missing')
elseif not(isfield(Copula, 'Parameters'))
    error('Field Copula.Parameters missing')
end

