function Copula = uq_PairCopula(family, theta, rotation)
% Copula = UQ_PAIRCOPULA(family, theta, rotation)
%     Convenience function to create a data structure for the specified 
%     pair copula. The structure is used in copula-related operations in 
%     UQlab, for instance as part of an input object.
%
% INPUT: 
% family: char or double
%     the pair copula family, either as a name (char) or id (integer)
% theta : array of doubles
%     the copula parameters
% (rotation: double, optional)
%     the rotation of the copula density. Can be: 0, 90, 180, 270.
%     Default: 0 (no rotation).
%     Note: rotations 90 and 270 are obtained by flipping the copula
%     density around the lines u1=0.5 and u2=0.5, respectively.
%
% OUTPUT:
% Copula : struct
%     Structure that describes the specified pair copula, with the fields:
%     .Type, .Family, .Dimension, .Parameters, .Rotation
%
% SEE ALSO: uq_VineCopula, uq_GaussianCopula

if nargin <=2, rotation = 0; end

Copula = uq_copula_skeleton();
Copula.Type = 'Pair';
Copula.Family = family;
Copula.Dimension = 2;
Copula.Parameters = theta;
Copula.Rotation = rotation;
