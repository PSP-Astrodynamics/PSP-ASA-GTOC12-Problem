function uq_check_copula_is_pair(Copula)
% UQ_CHECK_COPULA_IS_PAIR(Copula)
%     Checks that the input argument is a copula structure with field
%     .Type = 'Pair', and other needed fields. Raises an error otherwise
%
% INPUT:
% Copula : struct
%     A structure describing a pair copula (see uq_PairCopula)
%
% OUTPUT:
% none

if not(isfield(Copula, 'Type'))
    error('Field Copula.Type missing')
elseif not(strcmpi(Copula.Type, 'Pair'))
    error('Unknown copula Type %s. Specify ''Pair'' instead', Copula.Type);
elseif not(isfield(Copula, 'Family'))
    error('Field Copula.Family missing')
elseif not(isfield(Copula, 'Parameters'))
    error('Field Copula.Parameters missing')
elseif isfield(Copula, 'Dimension') && Copula.Dimension ~= 2
    error('Copula.Dimension is %d (must be 2 instead)', Copula.Dimension)
end

