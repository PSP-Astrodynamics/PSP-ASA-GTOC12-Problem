function eqrots = uq_pair_copula_equivalent_rotation(Family, rots)
% uq_pair_copula_equivalent_rotation(Family, rots)
%     Given a pair copula family and an array of rotations (with values in
%     {0, 90, 180, 270}), returns an array of equivalent rotations for that
%     family.
%     
%     Rotations of a pair copula density C are defined by:
%     C90(u,v) := C(1-u, v);    | flipping around horizontal axis u = 0.5
%     C180(u,v) := C(1-u, 1-v); | flipping around both axis u=0.5 and v=0.5
%     C270(u,v) := C(u, 1-v);   | flipping around vertical axis v = 0.5
%
%     Therefore:
%     * if a copula density is symmetric wrt either axis, the corresponding
%       rotation is equivalent to no rotation
%     * if a copula density is symmetric wrt both axis, all rotations are
%       equivalent to no rotation. This is e.g. the case of the Gaussian 
%       and t- pair copulas.

% By default, rotations are only equivalent to themselves
eqrots = rots;

% If a copula is symmetric wrt both axis, all rotations are equivalent
if any(strcmpi(uq_copula_stdname(Family), {'Independent', 'Gaussian', 't'}))
    eqrots = mod(eqrots, 90);
end
