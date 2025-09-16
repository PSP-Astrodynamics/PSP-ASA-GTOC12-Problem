function rots = uq_vine_copula_rotations(Copula)
% rot = uq_vine_copula_rotations(Copula)
%     determines array of rotations of each pair copula in the specified 
%     vine copula. If the field Copula.Rotations is missing, returns an 
%     array of zeros (the pair copulas are considered non-rotated).

uq_check_copula_is_vine(Copula);

if isfield(Copula, 'Rotations')
    rots = Copula.Rotations;
else
    rots = zeros(1, length(Copula.Families));
end
