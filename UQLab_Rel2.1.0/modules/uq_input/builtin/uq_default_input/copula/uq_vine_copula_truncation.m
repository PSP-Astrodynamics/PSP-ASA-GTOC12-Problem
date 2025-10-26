function T = uq_vine_copula_truncation(Copula)
% rot = uq_vine_copula_truncation(Copula)
%     determines the truncation level of the specified vine copula.
%     If the field Copula.Truncation is missing, returns the copula
%     dimension M (no truncation).

uq_check_copula_is_vine(Copula);

if isfield(Copula, 'Truncation')
    T = Copula.Truncation;
else
    T = uq_copula_dimension(Copula);
end
