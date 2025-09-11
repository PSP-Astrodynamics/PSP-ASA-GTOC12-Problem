function Copula = uq_IndepCopula(M)
% Copula = UQ_GAUSSIANCOPULA(C, corrType)
%     Creates a structure that describes an Independence copula of 
%     dimension M.
%
% INPUT:
% M : positive integer
%     copula dimension 
%
% OUTPUT:
% Copula : struct
%     Structure describing an Independent copula, with fields
%     .Type, .Dimension, .Parameters
%
% SEE ALSO: uq_PairCopula, uq_VineCopula, uq_GaussianCopula

Copula = uq_copula_skeleton(); 
Copula.Type = 'Independent'; 
Copula.Dimension = M;
Copula.Parameters = eye(M);
