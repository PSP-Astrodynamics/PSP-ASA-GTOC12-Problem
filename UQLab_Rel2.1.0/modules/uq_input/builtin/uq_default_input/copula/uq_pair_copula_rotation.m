function rot = uq_pair_copula_rotation(Copula)
% rot = uq_pair_copula_rotation(Copula)
%     determines rotation of the specified pair copula. If Copula has no 
%     field .Rotation, returns 0 (the copula is considered not rotated).
uq_check_copula_is_pair(Copula);

if isfield(Copula, 'Rotation')
    rot = Copula.Rotation;
else
    rot = 0;
end
